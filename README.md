# Erlang Vk API

Erlang Vkontakte API implementation.

## Usage

```sh
$ ./rebar3 tree  # Download deps
$ ./rebar3 compile # Compile project
$ ./rebar3 shell
```
*In shell*
```
1> vkapi:request("wall.get",[{"owner_id","1"}]).
```
First argument - method. Second - parameters in format [{"Key","Value"},{"Key","Value"},{"Key","Value"}]


## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for 
submitting pull requests to us.

## Authors

* **Vadim Romaniuk** - *Initial work* - [glicOne](https://github.com/RomaniukVadim)

See also the list of [contributors](https://github.com/ErlangBoys/vkapi/graphs/contributors) who 
participated in this project.

## License

This project is licensed under the GPL-3.0 License - see the [LICENSE.md](LICENSE.md) file for details.
