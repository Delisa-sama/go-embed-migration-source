package goembedmigrationsource

import (
	"bytes"
	"embed"
	"fmt"
	"io/ioutil"
	"sort"
	"strings"

	migrate "github.com/rubenv/sql-migrate"
)

// EmbedFileSystemMigrationSource implements migrate.MigrationSource interface for embed.FS.
type EmbedFileSystemMigrationSource struct {
	FileSystem embed.FS
	Dir        string
}

// FindMigrations returns a collection of migrations based on found .sql files in the FS.
func (f EmbedFileSystemMigrationSource) FindMigrations() ([]*migrate.Migration, error) {
	return f.findMigrations()
}

type byID []*migrate.Migration

func (b byID) Len() int           { return len(b) }
func (b byID) Swap(i, j int)      { b[i], b[j] = b[j], b[i] }
func (b byID) Less(i, j int) bool { return b[i].Less(b[j]) }

func (f EmbedFileSystemMigrationSource) findMigrations() ([]*migrate.Migration, error) {
	migrations := make([]*migrate.Migration, 0)

	dir, err := f.FileSystem.ReadDir(f.Dir)
	if err != nil {
		return nil, err
	}

	for _, file := range dir {
		if file.IsDir() {
			continue
		}
		if strings.HasSuffix(file.Name(), ".sql") {
			migration, err := f.migrationFromFile(file.Name())
			if err != nil {
				return nil, err
			}

			migrations = append(migrations, migration)
		}
	}

	// Make sure migrations are sorted
	sort.Sort(byID(migrations))

	return migrations, nil
}

func (f EmbedFileSystemMigrationSource) migrationFromFile(filename string) (*migrate.Migration, error) {
	path := fmt.Sprintf("%s/%s", f.Dir, filename)
	file, err := f.FileSystem.Open(path)
	if err != nil {
		return nil, fmt.Errorf("Error while opening %s: %s", filename, err)
	}
	defer func() { _ = file.Close() }()

	content, err := ioutil.ReadAll(file)
	if err != nil {
		return nil, fmt.Errorf("Error while reading %s: %s", filename, err)
	}

	migration, err := migrate.ParseMigration(filename, bytes.NewReader(content))
	if err != nil {
		return nil, fmt.Errorf("Error while parsing %s: %s", filename, err)
	}
	return migration, nil
}
