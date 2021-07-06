[![Stories in Ready](https://badge.waffle.io/innotop/innotop.png?label=ready&title=Ready)](https://waffle.io/innotop/innotop)

![innotop_logo2](https://user-images.githubusercontent.com/609675/48270427-5760d500-e43a-11e8-847b-240c27a957e0.png)

innotop
=======

![Snapshot of innotop query monitor](snapshot_queries.png "Snapshot of innotop query monitor")

innotop is a 'top' clone for MySQL with many features and flexibility.

* completely customizable; it even has a plugin interface
* monitors many servers at once and can aggregate across them 

The manual is embedded into the program in Perl's POD format, so it should be available 
through perldoc and man.

The full history has been imported in github.

Docker
------

```sh
docker build . -t innotop
docker run -it --rm \
  -v /var/run/mysqld/mysqld.sock:/var/run/mysqld/mysqld.sock:ro \
  -v $HOME/.innotop:/root/.innotop \
  innotop -u root -p xxxx
```
