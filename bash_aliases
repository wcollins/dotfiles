# ~/.bash_aliases

# system
alias ll='ls -al'
alias mkdir='mkdir -pv'
alias wget='wget -c'
alias reboot='sudo /sbin/reboot'
alias poweroff='sudo /sbin/poweroff'
alias halt='sudo /sbin/halt'
alias shutdown='sudo /sbin/shutdown'

# resources
alias df='df -Tha --total'
alias du='du -ach | sort -h'
alias free='free -mt'
alias ps='ps auxf'
alias ps?='ps aux | grep -v grep | grep -i -e VSZ -e'
alias meminfo='free -m -l -t'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias pscpu='ps auxf | sort -nr -k 3'
alias pscpu10='ps auxf | sort -nr -k 3 | head -10'
alias cpuinfo='lscpu'

# networking
alias ifconfig='/sbin/ifconfig'
alias route='/sbin/route'
alias ports='netstat -tulanp'
alias iptlist='sudo /sbin/iptables -L -n -v --line-numbers'
alias iptlistin='sudo /sbin/iptables -L INPUT -n -v --line-numbers'
alias iptlistout='sudo /sbin/iptables -L OUTPUT -n -v --line-numbers'
alias iptlistfw='sudo /sbin/iptables -L FORWARD -n -v --line-numbers'

# git
alias gi='git init'
alias gs='git status'
alias ga='git add'
alias gr='git rm'
alias gc='git commit -m'
alias gp='git pull origin master'
alias fgp='git fetch --all && git reset --hard origin/master'
alias gpm='git push -u origin master'

# docker
alias compose='docker-compose up -d'

# kvm
alias virsh='virsh --connect qemu:///system'

# colors
if [ -x /usr/bin/dircolors ]
then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias dir='dir --color=auto'
    alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi
