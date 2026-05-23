# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/).

## Daily workflow

Update the chezmoi source state from selected files:

```sh
~/chezmoi.sh
```

Review before staging:

```sh
chezmoi diff
chezmoi git -- status
```

Stage everything only after reviewing the diff:

```sh
chezmoi git -- add -A
```

Or stage interactively for safer commits:

```sh
chezmoi git -- add -p
```

Commit and push:

```sh
chezmoi git -- commit -m "update dotfiles"
chezmoi git -- push
```

## Secrets

Do not commit secrets to this repository.

Machine-local secrets live in:

```text
~/.zshrc.local
```

`~/.zshrc` sources that file when it exists:

```sh
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
```

Keep the local secrets file private:

```sh
chmod 600 ~/.zshrc.local
```

Never add it to chezmoi:

```sh
chezmoi add ~/.zshrc.local  # do not run this
```

## Repository-only files

`README.md` and `docs/**` are ignored by chezmoi via `.chezmoiignore`, so they can exist in this source repository without being applied into `$HOME`.

Verify ignored files with:

```sh
chezmoi ignored
```
