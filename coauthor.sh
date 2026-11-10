#!/usr/bin/env bash
# Usage : ./coauthor.sh <nom_utilisateur_github>
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage : $0 <nom_utilisateur>" >&2
  exit 1
fi

user="$1"
headers=(-H "Accept: application/vnd.github+json")
# Token facultatif, pour dépasser la limite de 60 requêtes/heure
[ -n "${GITHUB_TOKEN:-}" ] && headers+=(-H "Authorization: Bearer $GITHUB_TOKEN")

json=$(curl -fsS "${headers[@]}" "https://api.github.com/users/$user") || {
  echo "Erreur : utilisateur « $user » introuvable ou limite de l'API atteinte." >&2
  exit 1
}

if command -v jq >/dev/null 2>&1; then
  id=$(jq -r '.id' <<<"$json")
  login=$(jq -r '.login' <<<"$json")
  name=$(jq -r '.name // empty' <<<"$json")
else
  id=$(grep -m1 '"id":' <<<"$json" | sed -E 's/[^0-9]*([0-9]+).*/\1/')
  login=$(grep -m1 '"login":' <<<"$json" | sed -E 's/.*"login": *"([^"]*)".*/\1/')
  name=$(grep -m1 '"name":' <<<"$json" | sed -E 's/.*"name": *"?([^",]*)"?.*/\1/')
  [ "$name" = "null" ] && name=""
fi

name=${name:-$login}   # si pas de nom public, on prend le pseudo
line="Co-authored-by: $name <$id+$login@users.noreply.github.com>"

echo "$line"

# Sur macOS, copie aussi la ligne dans le presse-papiers
if command -v pbcopy >/dev/null 2>&1; then
  printf '%s' "$line" | pbcopy
  echo "(copié dans le presse-papiers)" >&2
fi