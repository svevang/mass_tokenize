# MassTokenize

MassTokenize converts English text files grouped in a directory and turns them
into a list of tokenized words.

MassTokenize accepts flags to parse the line-oriented JSON emitted by
[wikiextractor](https://github.com/attardi/wikiextractor) (see
`--json-lines`) or operates on raw text files e.g. from a corpus like
[Project Gutenberg](https://www.gutenberg.org/).

The resulting tokens are only partially deduplicated.

## Installation

Set up project dependencies and compile:

```
$ mix deps get

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

```
# e.g. `WikiExtractor.py --json -o /tmp/text <some enwiki-dump>`

$ mix run -e 'MassTokenize.CLI.run(["--path", "/tmp/text/AA", "--json"])'
<snip>

```





