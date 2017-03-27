# Automotivated development
Automotivated development is a [Docker](https://www.docker.com/) container setup for working on [Automotivated.vroom( )](https://github.com/Automotivated/vroom) or [Automotivated.engine( )](https://github.com/Automotivated/engine).

## Before we begin
Put on some nice [Electro Swing](https://www.youtube.com/watch?v=htbQgPh1DaA) and make sure you got the following applications installed:

- [Docker](https://www.docker.com/)

You can validate it by running `docker -v` in your favorite ([fish](https://fishshell.com/) || [zsh](http://www.zsh.org/)) flavoured ([oh-my-fish](https://github.com/oh-my-fish/oh-my-fish) || [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)) terminal ([iterm](https://www.iterm2.com/)).
It should output something like: `Docker version 17.03.0-ce, build 60ccb22`

First get the necessary dockerfiles by cloning this repository:
```sh
git clone https://github.com/Automotivated/development.git
```

From here we got two options:

1. Running the docker for active development on the projects
2. Improving the docker containers

## 1. Running the docker

### 1.1 Installation
First make a copy of the `.env.dist` file and name it `.env`. Now adjust the configuration accordingly.

```sh
cp .env.dist .env
```
When your smart, you will install all Automotivated projects in the same namespace. Therefore linking and developping is much easier.

```
/users/myname/home/project/Automotivated/development
/users/myname/home/project/Automotivated/engine
/users/myname/home/project/Automotivated/vroom
....
```
When you use this format, you should run into any troubles when you set the `PROJECT_ROOT=../`
If you somehow want to setup things differently, make sure you adjust the `root /var/www/Automotivated/engine/web;` in the `default.conf` of nginx before proceeding!

### 1.2 Building & running
Navigate to the project root directory. Probably you have to build the images on your local machine first. Do so by running:

```sh
docker-compose build
```
It will do a lot of stuff, like pulling all dependencies and building the environment.
Now, with everything in place, just run:

```sh
docker-compose up -d
```
The `-d` will run it in the background so you don't have to keep your terminal open.

Now, just navigate to: [http://127.0.0.1:3000](http://127.0.0.1:3000). You should see the default server is up page. If not.. Goto step 2 and improve the docker!

### 1.3 Logging in to the environments
Mostly we should login to the php environment for example, run the `bin/console` or `composer` commands
```
docker exec -it amv-dev /bin/sh
```

### 1.4 Composer
Once logged in, navigate to `/var/www/Automotivated/engine` and run `composer install`

```
cd /var/www/Automotivated/engine
composer install
```

### 1.5 Off you go!
[http://127.0.0.1:3000/app_dev.php/api/search](http://127.0.0.1:3000/app_dev.php/api/search)

## 2. Improving the environments
Make your changes..

Create a Pull request

Fingers crossed it get's merged

## TODO
- [x] Add composer to the php library
- [x] Better logging (nginx)
- [ ] Get some inspiration from here: https://github.com/maxpou/docker-symfony
- [ ] Smaller mysql package: https://github.com/wangxian/alpine-mysql
