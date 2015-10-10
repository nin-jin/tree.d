# Tree
Simple fast compact user-readable binary-safe extensible structural format.

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
Prevalence                         |  5   |  5  |  3   |  3  |  0
Text editors support               |  5   |  5  |  3   |  5  |  1
Languages support                  |  4   |  5  |  3   |  5  |  1

## Short description

Structural-nodes represents as names that can not contain `[\s\n=]`. Example of structural nodes:

```tree
first-level second-level third-level
first-level
	first-of-second-level third-level
	second-of-second-level
```

Indents must use tabs, lines must use unix line ends.

Data-nodes represents as raw data between `[=]` and `[\n]` characters. Example

```tree
=hello
=world
=
	=hello
	=world
```

In one line may be any count of structural-nodes, but only one data-node at the end. 

```tree
article
	title =Hello world
	description
		=This is demo of tree-format
		=Cool! Is not it? :-)
```

[Grammar using grammar.tree language](./tree.grammar.tree)

[More examples.](./examples/)

[More info about format and tree-based languages (russian article).](http://habrahabr.ru/post/248147/)

## IDE support

* [SynWrite](http://www.uvviewsoft.com/synwrite/)
* [Syntax highlighting for IntelliJ IDEA](https://plugins.jetbrains.com/plugin/7459)

## D API

### Parsing

```d
    string data = cast(string) read( "path/to/file.tree" ); // read from file
    Tree tree = Tree.parse( data , "http://example.org/source/uri" ); // parse to tree
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
