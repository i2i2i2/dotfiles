function fish_prompt
  if test -n "$SSH_CONNECTION"
    printf '%s ' $HOSTNAME
  end

  set_color brgreen
  printf "\$"
  set_color normal
  printf " "
end
