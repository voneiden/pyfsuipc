# pyfsuipc

pyfsuipc is a Python 3 compatible Cython module that allows interfacing with 
FSUIPC via Pete Dowson's FSUIPC_User library.

Currently the project is still in brainstorming phase, so expect things to change and break.

## Requirements

1. [Python 3](https://www.python.org/)
2. [Cython](http://cython.org/)
3. A compiler, for example [MinGW](http://www.mingw.org/). See Cython documentation for [setup instructions](http://docs.cython.org/src/tutorial/appendix.html).


## Compiling

1. Run 'python setup.py build'
2. The ready to use module can be found from build/lib.win32-3.4/pyfsuipc.pyd


## Contributing

Contributions are welcome. Let's try to keep the module as simple as possible though

## License

FSUIPC_User libraries are copyrighted to Pete Dowson. Not so sure about the license. The rest is GPL 3.