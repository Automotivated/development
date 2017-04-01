# Docker development containers
This repository is a setup for working on a development machine and you want to run on [docker](https://www.docker.com/). It's mostly build on the edge version of [Alpine Linux](https://alpinelinux.org/). 
If you are a developer looking into this repo and don't own a Mac, hmm.. don't know if it's going to work right out of the box. PR's are appreciated!

I set it up for the Automotivated projects [Automotivated.vroom( )](https://github.com/Automotivated/vroom) and [Automotivated.engine( )](https://github.com/Automotivated/engine), but kept it general so others can enjoy my effort.

It contains setups for the following containers:

> apache  
 mysql  
 nginx  
 php  
 elasticsearch

## Before we begin
Put on some nice [Electro Swing](https://www.youtube.com/watch?v=htbQgPh1DaA) and make sure you got the following applications installed:

- [Docker](https://www.docker.com/)

You can validate it by running `docker -v` in your favorite ([fish](https://fishshell.com/) || [zsh](http://www.zsh.org/)) flavoured ([oh-my-fish](https://github.com/oh-my-fish/oh-my-fish) || [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)) terminal ([iterm](https://www.iterm2.com/)).
It should output something like: `Docker version 17.03.0-ce, build 60ccb22`

First get the necessary files by cloning this repository:
```sh
git clone https://github.com/Automotivated/development.git
```

## 1. Installation
This repository comes with a script that can handle all important stuff! Sweet!  
Just open your terminal and go to the root of this project. If you're using `fish`, prefix `/bin/sh`

`/bin/sh run.sh install`

If you somehow forget the `install` argument, the script will print out the help. Also available under `run.sh -h` or `run.sh --help`

```
Usage: run.sh COMMAND

Options:
    -h,   --help              Will print this message
    -p,   --project           Custom project namespace
    -v,   --verbose           Will output everything
    -f,   --force-recreate    Force recreation

Commands:
    install                   Start a fresh installation
    add                       Add a new domain / project
    up                        Will bring the services up
    down                      Shutsdown all services
```
The installation will ask you some questions and if you fill them in correctly you'll end up with an `.config` and `.env`
The `.config` is for future reference and the `.env` is a default [docker compose environment file](https://docs.docker.com/compose/environment-variables/#the-env-file).
You can change the contents of the `.env` to your own likings, but please be advised that the run script is depending on it!

## 2. Firing up the development environment
This shouldn't be that hard!

`/bin/sh run.sh up`

Want to know what's happening in the background? Just add the `-v` flag for some verbose output.

## 3. Show me the money!

Now, just navigate to: [http://127.0.0.1](http://127.0.0.1). You should see the default server is up page.
> We added in the script an alias for your domain, so you can use that instead. If something already runs on port 80, shut that down!

## 4. Logging in into the containers
Mostly we should login to the php container for example, run the `bin/console` or `composer` commands  
If you didn't choose your own namespacing for the project with the `-p` operator, then the following command should do it:

```
docker exec -it devenv_php_1 /bin/sh
```

If however you changed the project name, then replace `<container>` with your own project name followed by _php_1

```
docker exec -it <container> /bin/sh
```


## 5. Manual installation and running
Okay, so you're a badass! Good for you! Get to know [docker compose](https://docs.docker.com/compose/) and use this repo as a guideline.
Make sure to create a valid docker-compose.yml or use the `-f` operator like we do in the run.sh.


## 6. Improving the environments
Make your changes..  
Create a Pull request  
Fingers crossed it get's merged

## TODO
- [ ] Add ssh inlog to run.sh
- [ ] Add 
