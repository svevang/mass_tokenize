# MassTokenize

MassTokenize turns a directory of text files containing English prose
into a list of words. This is a process used in Natural Language
Processing (NLP) called
[tokenization](https://www.ibm.com/developerworks/community/blogs/nlp/entry/tokenization?lang=en).
Eventually this list of words will become a
[trie](https://en.wikipedia.org/wiki/Trie) of all the words in the
Wikipedia.

## Elixir!

Welcome to the world of Elixir (Erlang)!

 MassTokenize creates a pipeline of lightweight
Elixir processes to tokenize the text.

Pipeline Steps:

1) Read the files from disk
2) Parse the file and tokenize the English phrases in the file.
3) Emit the tokens, one per line.

Each step is an queue backed by a group of worker processes.

## Installation

Set up project dependencies and compile:

```
$ mix deps.get

$ mix compile
```

If you're interested in using the Wikipedia as a data source, download
the latest dump:

```
$ wget -np -r --accept-regex
'https://dumps.wikimedia.org/enwiki/latest/enwiki-latest-pages-articles[0-27].*.bz2'
https://dumps.wikimedia.org/enwiki/latest/
```

And then follow the instructions over at
[wikiextractor](https://github.com/attardi/wikiextractor) to extract the
cleaned up json output.

## Usage

Basic usage information is provided by the CLI module:

```
$ mix run -e 'MassTokenize.CLI.run(["--help"])'

Generated mass_tokenize app
Usage: mass_tokenize [OPTIONS] 

  Tokenize a text file or directory: $ mass_tokenize --path <some/path>
  Print this help:                   $ mass_tokenize --help

Options:
  --wikiextractor-json  Assume the input format is wikiextractor line-oriented json objects
  --help/-h             Print this help

```

### Tokenizing Plain Text

Let's take the Project Gutenberg edition of __Moby Dick__ and tokenize
it:

```
# create a folder and download the book
$ $(mkdir -p /tmp/text && cd /tmp/text && wget https://www.gutenberg.org/files/2701/2701-0.txt)

# invoke the MassTokenize app
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

### Tokenizing Wikiextractor Json Output

Wikiextractor is a useful tool for preprocessing Wikipedia dumps.
MassTokenize understands the JSON formatted dump structure that
Wikiextractor uses. To try this out, download and run the Wikiextractor
tool on an enwiki dump:


```
$ WikiExtractor.py --json -o /tmp/text <some enwiki-dump>

```

Then we're ready to tokenize:

```
$ mix run -e 'MassTokenize.CLI.run(["--path", "/tmp/text/AA", "--json"])'
```

## InteractingScheduler: The Story of an Objective Function.

An objective function represents a goal. In our case you can think of it
as a way to minimize our memory usage while keeping the pipeline full.
At each step in the pipeline, we want to ensure that a "thundering herd"
of work is not created for subsequent steps. In cases where the total
work is larger than memory (like the enwiki dumps) our program could
crash with an out of memory error. So at each step in our program we ask
the objective function "Should we add more work?", if the answer is yes
we pile more work on. If the answer is no then we take 5 and relax,
letting the pipeline settle down.

  Starting with the [`Scheduler` example
code](https://gist.github.com/svevang/de9fdcb4bf47413789dec0fbc742a020)
in Dave Thomas' __Programming Elixir__ (which by the way is a great book
to learn Elixir), I've added a notion of _interaction_ between worker
queues: Basically one scheduler responds to something happening on
another scheduler. To make that work, there are some requirements for
our new `InteractingScheduler` module:

1) The work queue may become empty.
2) Work may be added to the queue at a later time.

In the original Scheduler implementation, workers simply [request the
next piece of
work](https://gist.github.com/svevang/de9fdcb4bf47413789dec0fbc742a020#file-fib-exs-L40).
But because of the above requirements, we have to track the state of our
workers: either 'working' or 'available'. Once work is added to the
queue, we start our workers with a call to
`InteractingScheduler.schedule_processes`: Any available workers grab a
unit of work and begin processing.

The receive block was factored out of the `Scheduler` and is now part of
the main program loop. (If you dont know what a receive block is,
basically it's how Erlang and [Elixir communicate between
processes](https://elixir-lang.org/getting-started/processes.html#send-and-receive)).
This allows MassTokenize to act as a router for pipeline events. When
we receive messages from one step in the pipeline, we pass them onward
to the next step. There is a little bookkeeping involved: you must call
`InteractingScheduler.receive_answer` whenever a worker returns an
answer. This lets the scheduler know which workers are idle.

### Objective!

An objective function represents a goal. In our case you can think of it
as a way to minimize a number (memory usage). At this point there's
enough information in the main loop to create our objective function.

We monitor the next pipeline step and [make sure
_that_ queue is
bounded](https://github.com/svevang/mass_tokenize/blob/master/lib/mass_tokenize.ex#L39). 

To verify that our objective function is working, we can install
[Wobserver](https://github.com/shinyscorpion/wobserver) and take a look
at how this app allocates memory on very large input:
![example memory usage](https://raw.githubusercontent.com/svevang/mass_tokenize/feature/load-testing/memory_usage.png)
Looks great! Memory usage remains constant. Our objective function is working.
