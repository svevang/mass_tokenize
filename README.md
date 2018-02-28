# MassTokenize

MassTokenize explores how to turn a directory of text files containing
English prose into a series of tokens. This is a basic process used in
Natural Language Processing (NLP) called
[tokenization](https://www.ibm.com/developerworks/community/blogs/nlp/entry/tokenization?lang=en).

## Elixir! (_*Cough* Erlang_)

Welcome to the world of Elixir!

Elixir allows us to use concurrency to break up the problem of
tokenization into smaller tasks and run them through a pipeline.

Pipeline Steps:

1) Read the files from disk
2) Parse the file and tokenize the English phrases in the file.

These steps are implemented as a queue serviced by worker processes.

## Installation

Set up project dependencies and compile:

```
$ mix deps.get

$ mix compile
```

## Usage

### Raw Text

Process Moby Dick into tokens:

```
$ $(mkdir -p /tmp/text && cd /tmp/text && wget https://www.gutenberg.org/files/2701/2701-0.txt)
$ mix run -e 'MassTokenize.CLI.run(["--path", "/tmp/text"])'

The
Project
Gutenberg
EBook
of
Moby
Dick
or
Whale
by
Herman
<snip>
```

### Processing Wikiextractor Json Output

Wikiextractor is a useful tool for preprocessing Wikipedia dumps.
MassTokenize understands the JSON formatted dump structure that
Wikiextractor uses. To try this out, download and run the Wikiextractor
tool on a enwiki dump:


```
$ WikiExtractor.py --json -o /tmp/text <some enwiki-dump>

```

Then we are ready to tokenize:

```
$ mix run -e 'MassTokenize.CLI.run(["--path", "/tmp/text/AA", "--json"])'
```

## InteractingScheduler

At each step in the pipeline, we want to ensure that memory usage
remains constant, so that any particular step in the pipeline doesn't
crash our program by sending a "thundering herd" to a subsequent step.
Starting with the [`Scheduler`
example](https://gist.github.com/svevang/de9fdcb4bf47413789dec0fbc742a020)
code in Dave Thomas' __Programming Elixir__, I've added a notion of
_interaction_ between worker queues. This sets up some requirements for
our new `InteractingScheduler`:

1) The work queue may become empty.
2) Work may be added to the queue at a later time.

In the original Scheduler implementation, workers simply [request the
next piece of
work](https://gist.github.com/svevang/de9fdcb4bf47413789dec0fbc742a020#file-fib-exs-L40).
But because of the above requirements, we have to track the state of our
workers: either `working` or `available`. This allow an objective
function to throttle a scheduler queue. For mass tokenize, this is
pretty easy: monitor the next pipeline step and [make sure _that_ queue
is
bounded](https://github.com/svevang/mass_tokenize/blob/master/lib/mass_tokenize.ex#L39).

Additionally, the receive block is now in the main program loop. This
allows our program to act as the router for pipeline events. When we
receive messages from one step in the pipeline, we can pass them onward.
