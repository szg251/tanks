printf "\nStarting deployment to Gigalixir\n\n"

git remote add gigalixir https://$GIGALIXIR_EMAIL:$GIGALIXIR_API_KEY@git.gigalixir.com/$GIGALIXIR_APP_NAME.git
git push -f gigalixir HEAD:refs/heads/master