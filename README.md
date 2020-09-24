# Make You a Database

[![Actions Status](https://github.com/cuzzo/make-you-a-database/workflows/Ruby/badge.svg)](https://github.com/cuzzo/make-you-a-database/actions)

I'm building a simple database to get a better understanding of how databases actually work. The goal is to focus on making the code as easy to follow and understand as possible.

This is a learning experience I'll be documenting as I go.

As such, performance and reliability are not top concerns. You should use this for educational purposes only.

## Reasoning

I'm an Engineer at Google, and my job revolves around [Spanner](https://cloud.google.com/spanner) -- Google's Distributed Database. It's pretty much the coolest thing in the world to me -- literally it's like magic.

I hope to one day understand it.

Reading documentation and books is great, but for me, nothing beats hands on experience, so I thought I would try to build the simpliest possible distributed database to get a better understanding on how Spanner works.

## Architecture
![SQLite Architecture Diagram](/docs/arch.gif)

For now, I'm focused on building something much, much simpler than Spanner.  I'm building the the most basic version of SQLite I can imagine.

## Design Decisions

I've chosen Ruby as a starting language because it's one of my strongest languages. Although Ruby syntax can get a bit funky, it's also pretty easy for beginners to pick up and understand.

After I get a better understanding of how databases actually work, I will likely switch to a different language.

## Acknowledgements

* [cstack DB Tutorial](https://cstack.github.io/db_tutorial/) - on which this code is based
* [Learn You Some Erlang](https://learnyousomeerlang.com/content) - on which the documentation will be based
