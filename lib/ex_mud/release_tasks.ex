# From https://github.com/bitwalker/distillery/blob/master/docs/Running%20Migrations.md
defmodule ExMud.ReleaseTasks do
  @start_apps [
    :postgrex,
    :ecto
  ]

  @apps [
    :ex_mud
  ]

  @repos [
    Data.Repo
  ]

  def migrate do
    IO.puts "Loading ex_mud..."
    # Load the code for ex_mud, but don't start it
    :ok = Application.load(:ex_mud)

    IO.puts "Starting dependencies.."
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for ex_mud
    IO.puts "Starting repos.."
    Enum.each(@repos, &(&1.start_link(pool_size: 1)))

    # Run migrations
    Enum.each(@apps, &run_migrations_for/1)

    # Signal shutdown
    IO.puts "Success!"
    :init.stop()
  end

  def priv_dir(app), do: "#{:code.priv_dir(app)}"

  defp run_migrations_for(app) do
    IO.puts "Running migrations for #{app}"
    Ecto.Migrator.run(Data.Repo, migrations_path(app), :up, all: true)
  end

  defp migrations_path(app), do: Path.join([priv_dir(app), "repo", "migrations"])
end