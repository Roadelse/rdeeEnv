#!/bin/bash

set -e

#@ <.bash_profile> source ~/.profile in ~/.bash_profile
if [[ -n `grep -P '# >>* \[\.profile\]' ~/.bash_profile 2>/dev/null` ]]; then
    sed -i '/^# >* \[.profile\]/,/^$/c\
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile]\
if [ -f ~/.profile ]; then\
   . ~/.profile\
fi\
' ~/.bash_profile
else
    if [[ ! -e ~/.bash_profile ]]; then   #>- added @2024-01-05 22:44:58
        echo -e "#!/bin/bash\n\n" > ~/.bash_profile
    fi
        
    cat << EOF >> ~/.bash_profile

# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile]
if [ -f ~/.profile ]; then
   . ~/.profile
fi

EOF
fi
#@ <.bash_profile/>

#@ <.profile> handle ~/.profile.d in ~/.profile
mkdir -p $HOME/.profile.d
if [[ -n `grep -P '# >>* \[\.profile.d\]' ~/.profile 2>/dev/null` ]]; then
    sed -i '/^# >* \[.profile.d\]/,/^$/c\
# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile.d]\
if [ -d "$HOME/.profile.d" ]; then\
  for profile_script in "$HOME/.profile.d/"*.sh; do\
    if [ -x "$profile_script" ]; then\
      . "$profile_script"\
    fi\
  done\
fi\
' ~/.profile
else
    if [[ ! -e ~/.profile ]]; then   #>- added @2024-01-05 22:44:58
        echo -e "#!/bin/bash\n\n" > ~/.profile
    fi
        
    cat << EOF >> ~/.profile

# >>>>>>>>>>>>>>>>>>>>>>>>>>> [.profile.d]
if [ -d "$HOME/.profile.d" ]; then
  for profile_script in "$HOME/.profile.d/"*.sh; do
    if [ -x "\$profile_script" ]; then
      . "\$profile_script"
    fi
  done
fi

EOF
fi
#@ <.profile/>


