## This is a Proof of Concept for using the embed package in conjunction with sql-migrate.

## Example

``` go
import (
	"embed"

	embedmigrations "github.com/Delisa-sama/go-embed-migration-source"
)

//go:embed migrations
var migrationFiles embed.FS

// MigrationSource embedded migration source.
var MigrationSource = &embedmigrations.EmbedFileSystemMigrationSource{
	FileSystem: migrationFiles,
	Dir:        "migrations",
}
...
num, err := sqlmigrate.ExecMax(
  db,
  dialect,
  MigrationSource,
  sqlmigrate.Up,
  limit,
)
if err != nil {
  return err
}
```
