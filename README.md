![nativegen logo](https://raw.githubusercontent.com/yoavlt/nativegen/master/nativegen.png)
========

[![Build Status](https://travis-ci.org/yoavlt/nativegen.svg)](https://travis-ci.org/yoavlt/nativegen)
[![Coverage Status](https://coveralls.io/repos/yoavlt/nativegen/badge.svg?branch=master&service=github)](https://coveralls.io/github/yoavlt/nativegen?branch=master)
[![hex.pm version](https://img.shields.io/hexpm/v/nativegen.svg)](https://hex.pm/packages/nativegen)

Nativegen is a native app accessing REST API source code generator.
It is supported just Swift code now, but will Android, Unity and so on.

## Installation

You can add dependency to your project's `mix.exs`.

```:elixir
  defp deps do
    [
      {:nativegen, "~> 0.1.0"}
    ]
  end
```

then,

```:sh
$ mix do deps.get, mix compile
```

## Usage(Swift)

First, you have to setup.

```:sh
$ mix nativegen.swift.setup /your/to/your/directory
```

Next, following command will generate accessible REST API swift code.

```sh:
$ mix nativegen.swift.create /path/to/your/directory User users username:string group:Group items:array:Item
```

And, generate Json model the following command.

```sh:
$ mix nativegen.swift.model Item name:string strength:integer
```

Also, append model in your swift code.

```sh:
$ mix nativegen.swift.model Item name:string strength:integer --file /path/to/your/repo.swift
```

You can also generate methods

```sh:
$ mix nativegen.swift.method post /api/chat/response responseMessage Chat thread_id:integer message:string
```
