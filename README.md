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

## 1. Setting up
#### 1.1 Installation
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

#### 1.2 Creating a new project
When you run the fresh install, it will automatically fire up the add project procedure. You can offcourse as many projects as you like. To add a project simply run:
```sh
/bin/sh run.sh add
```
This setup will follow a few important rules! First, the created folder structure will be named to the domainname you filled in in the process.
All generated config files point to that directory and the script will add that domainname to the /etc/hosts file. So it's good practice to keep it like a real tld: `my-awesome-project.local` or ` my-awesome-project.dev`  
Your freshly squeezed project will be available under that domain and you find your files in: `projects/my-awesome-project.dev` See chapter 2 for existing projects.

#### 1.3 Firing up the development environment
This shouldn't be that hard!

```
/bin/sh run.sh up
```

Want to know what's happening in the background or do some troubleshooting? Just add the `-v` flag for some verbose output.

#### 1.4 Show me the money!

Now, just navigate to: [http://127.0.0.1](http://127.0.0.1) or your chosen domainname. You should see the default server is up page.
> If something already runs on port 80, shut that down!

#### 1.5 Logging in into the containers
Mostly we should login to the php container for example, run the `bin/console` or `composer` commands  
If you didn't choose your own namespacing for the project with the `-p` operator, then the following command should do it:
> We're working on creating a command to do this automatically.

```
docker exec -it devenv_php_1 /bin/sh
```

If however you changed the project name, then replace `<container>` with your own project name followed by _php_1

```
docker exec -it <container> /bin/sh
```

## 2. Adding an existing project
Offcourse you already have a project loaded into somesort of git repository. To make this work, follow these steps.

1. Add project like described in chapter 1.2
2. Clone the root of your project into the created folder
3. Fix any bugs like vhosts settings

## 3. Manual installation and running
Okay, so you're a badass! Good for you! Get to know [docker compose](https://docs.docker.com/compose/) and use this repo as a guideline.
Make sure to create a valid docker-compose.yml or use the `-f` operator like we do in the run.sh.

## 4. Improving the environments
Make your changes..  
Create a Pull request  
Fingers crossed it get's merged

## TODO
- [ ] Add ssh inlog to run.sh
- [ ] Add templating for project types
 - [ ] Initial wordpress template with bedrock
 - [ ] Clean symfony template
- [ ] Add database to mysql when adding new project
- [x] Multidomain alias
