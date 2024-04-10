# Tree
Simple fast compact user-readable binary-safe extensible structural format. Read more in a [detailed overview](https://hackernoon.com/tree-ast-which-crushes-json-xml-yaml-toml-etc).

[![Build Status](https://travis-ci.org/nin-jin/tree.d.svg?branch=master)](https://travis-ci.org/nin-jin/tree.d)

more - better                      | JSON | XML | YAML | INI | Tree
-----------------------------------|------|-----|------|-----|-----
Readability                        |  3   |  1  |  4   |  5  |  5
Edit-friendly                      |  3   |  1  |  4   |  5  |  5
Deep hierarchy                     |  3   |  3  |  3   |  1  |  5
Simple to implement                |  3   |  2  |  1   |  5  |  5
Performance                        |  3   |  1  |  1   |  5  |  5
Size                               |  3   |  1  |  4   |  5  |  5
Streaming                          |  0   |  0  |  5   |  5  |  5
Binary-safe                        |  2   |  0  |  0   |  0  |  5
Universality                       |  4   |  3  |  3   |  1  |  5
Prevalence                         |  5   |  5  |  3   |  3  |  1
Text editors support               |  5   |  5  |  3   |  5  |  3
Languages support                  |  4   |  5  |  3   |  5  |  2

## Short description

Structural-nodes represents as names that can not contain `[\s\n\\]`. Example of structural nodes:

```tree
first-level second-level third-level
first-level
	first-of-second-level third-level
	second-of-second-level
```

Indents must use tabs, lines must use unix line ends.

Data-nodes represents as raw data between `[\\]` and `[\n]` characters. Example

```tree
\hello
\world
\
	\hello
	\world
```

In one line may be any count of structural-nodes, but only one data-node at the end. 

```tree
article
	title \Hello world
	description
		\This is demo of tree-format
		\Cool! Is not it? :-)
```

[Reference Implementation](https://github.com/hyoo-ru/mam_mol/tree/master/tree2)

[Grammar using grammar.tree language](https://github.com/nin-jin/tree.d/wiki/grammar.tree)

[Tree based languages](https://github.com/nin-jin/tree.d/wiki/Tree-based-languages)

[More examples.](./examples/)

[Online sandbox](https://tree.hyoo.ru/)

## Performances

- [Tree - единый AST чтобы править всеми](https://github.com/nin-jin/slides/tree/master/tree) - more info about format and tree-based languages
- [Что не так с сорсмапами и как с ними не связываться?](https://github.com/nin-jin/slides/tree/master/sourcemap) - using tree for DSL with sourcemaps

## IDE support

* [SynWrite](http://www.uvviewsoft.com/synwrite/)
* [Syntax highlighting for IntelliJ IDEA](https://plugins.jetbrains.com/plugin/7459)
* [Syntax highlighting for Atom](https://github.com/nin-jin/atom-language-tree)
* [Syntax highlighting for Visual Studio Code](https://github.com/nin-jin/vscode-language-tree)
* [Syntax highlighting for Sublime](https://github.com/yurybikuzin/Smol-sublime)
* [Syntax highlighting for Emacs](https://github.com/osv/mol-tree-mode)

## Other implementations

* [TypeScript](https://github.com/eigenmethod/mol/tree/master/tree2)

## Similar formats

- [Tree Notation](https://github.com/treenotation/faq.treenotation.org)

## D API

### Parsing

```d
    string data = cast(string) read( "path/to/file.tree" ); // read from file
    Tree tree = new Tree( data , "http://example.org/source/uri" ); // parse to tree
```

### Simple queries

```d
    Tree userNames = tree.select( "user name" ); // returns name-nodes
    Tree userNamesValues = tree.select( "user name " ); // returns value-nodes
```

### Node info

```d
    string name = userNames[0].name; // get node name
    string stringValue = userNames[0].value; // get value as string with "\n" as delimiter
    uint intValue =  userNames[0].value!uint; // get value converted from string to another type

    Tree[] childs = tree.childs; // get child nodes array
    string baseUri = tree.baseUri; // get base uri like "http://example.org/source/uri"
    size_t row = tree.row; // get row in source stream
    size_t col = tree.col; // get column in source stream
    string uri = tree.uri; // get uri like "http://example.org/source/uri#3:2"
```

### Nodes creation

```d
	Tree values = Tree.Values( "foo\nbar" , [] );
	Tree name = Tree.Name( "name" , values );
	Tree list = Tree.List( [ name , name ] );
	Tree firstLineName = name.clone( [ name[0] );
```

### Serialization

```d
    string data = tree.toString(); // returns string representation of tree
    tree.pipe( stdout ); // prints tree to output buffer
```

# Benchmarks

```d
void main() {
	
	import std.datetime.stopwatch, std.json, jin.tree, std.stdio, std.file;
	
	string dataTree = cast(string) read( "formats/sample.tree" );
	string dataJson = cast(string) read( "formats/sample.json" );
	
	Tree tree;
	JSONValue json;
	
	void measureTree() {
    	tree = new Tree( dataTree , "formats/sample.tree" );
	}
	
	void measureJson() {
    	json = parseJSON( dataJson );
	}
	
	auto res = benchmark!( measureTree, measureJson )(100);
	
	res.writeln;
}
```

```sh
rdmd source/bench --build=release
```

## Parse

| jin.tree | std.json
|----------|---------
| 204 ms   | 372 ms
