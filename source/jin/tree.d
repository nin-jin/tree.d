module jin.tree;

import std.stdio;
import std.string;
import std.conv;
import std.outbuffer;
import std.algorithm;
import std.array;
import std.json;
import std.xml;
import std.file;
import std.path;

class Tree {

	string name;
	string value;
	string baseUri;
	size_t row;
	size_t col;
	Tree[] childs;

	this(
		 string name ,
		 string value ,
		 Tree[] childs ,
		 string baseUri = "" ,
		 size_t row = 0 ,
		 size_t col = 0 
	) {
		this.name = name;
		this.value = value;
		this.childs = childs;
		this.baseUri = baseUri;
		this.row = row;
		this.col = col;
	}

	this (
		  DirEntry input ,
		  string baseUri = null ,
		  size_t row = 1 ,
		  size_t col = 1
	) {
		if( baseUri is null ) baseUri = absolutePath( input.name );
		this( cast( string ) read( input.name ) , baseUri , row , col );
	}

	this (
		  File input ,
		  string baseUri = null ,
		  size_t row = 1 ,
		  size_t col = 1
	) {
		if( baseUri is null ) baseUri = input.name.absolutePath.asNormalizedPath.array;
		this( cast( string ) read( input.name ) , baseUri , row , col );
	}

	unittest {
		assert( new Tree( "foo\nbar\n" , "" ).length == 2 );
		assert( new Tree( "foo\nbar\n" , "" )[1].name == "bar" );
		assert( new Tree( "foo\n\n\n" , "" ).length == 1 );

		assert( new Tree( "\\foo\n\\bar\n" , "" ).value == "foo\nbar" );
		assert( new Tree( "\\foo\n\\bar\n" , "" ).length == 0 );

		assert( new Tree( "foo bar \\pol" , "" )[0][0].value == "pol" );
		assert( new Tree( "foo bar\n\t\\pol\n\t\\men" , "" )[0][0].value == "pol\nmen" );
	}
	this (
		  string input ,
		  string baseUri ,
		  size_t row = 1 ,
		  size_t col = 1
	) {
		this( "" , null , [] , baseUri , row , col );
		Tree[] stack = [ this ];

		Tree parent = this;
		while( input.length ) {

			auto name = input.takeUntil( "\t\n \\" );
			if( name.length ) {
				auto next = new Tree( name , null , [] , baseUri , row , col );
				parent.childs ~= next;
				parent = next;
				col += name.length + input.take( " " ).length;
				continue;
			}
			if( !input.length ) break;

			if( input[0] == '\\' ) {
				auto value = input.takeUntil( "\n" )[ 1 .. $ ];
				if( parent.value is null ) parent.value = value;
				else parent.value ~= "\n" ~ value;
			}
			if( !input.length ) break;

			if( input[0] != '\n' ) {
				throw new Exception( "Unexpected symbol (" ~ input[0] ~ ")" );
			}
			input = input[ 1 .. $ ];
			col = 1;
			row += 1;

			auto indent = input.take( "\t" ).length;
			col = indent;
			if( indent > stack.length ) {
				throw new Exception( "Too many TABs " ~ row.to!string ~ ":" ~ col.to!string );
			}

			stack ~= parent;
			stack.length  = indent + 1;
			parent = stack[ indent ];
		}
	}

	Tree make(
		string name = null ,
		string value = null ,
		Tree[] childs = null ,
		string baseUri = null ,
		size_t row = 0 ,
		size_t col = 0 
	) {
		return new Tree(
			name ? name : this.name ,
			value ? value : this.value ,
			childs ? childs : this.childs ,
			baseUri ? baseUri : this.baseUri ,
			row ? row : this.row ,
			col ? col : this.col
		);
	}

	static Tree fromJSON( string json ) {
		return Tree.fromJSON( parseJSON( json ) );
	}
	static Tree fromJSON( JSONValue json ) {
		switch( json.type ) {
			case JSON_TYPE.FALSE :
				return new Tree( "false" , "" , [] );
			case JSON_TYPE.TRUE :
				return new Tree( "true" , "" , [] );
			case JSON_TYPE.NULL :
				return new Tree( "null" , "" , [] );
			case JSON_TYPE.FLOAT :
				return new Tree( "float" , json.floating.to!string , [] );
			case JSON_TYPE.INTEGER :
				return new Tree( "int" , json.integer.to!string , [] );
			case JSON_TYPE.UINTEGER :
				return new Tree( "int" , json.uinteger.to!string , [] );
			case JSON_TYPE.STRING :
				return new Tree( "string" , json.str , [] );
			case JSON_TYPE.ARRAY :
				return new Tree( "list" , "" , json.array.map!( json => Tree.fromJSON( json ) ).array );
			case JSON_TYPE.OBJECT :
				Tree[] childs = [];
				foreach( key , value ; json.object ) {
					childs ~= new Tree( "*" , key , [ new Tree( ":" , "" , [ Tree.fromJSON( value ) ] ) ] );
				}
				return new Tree( "dict" , "" , childs );
			default:
				throw new Error( "Unsupported type: " ~ json.type );
		}
	}

	static Tree fromXML( string xml ) {
		return Tree.fromXML( new Document( xml ) );
	}
	static Tree fromXML( Item xml ) {

		auto el = cast( Element ) xml;
		if( el ) {
			Tree[] attrs;
			foreach( key , val ; el.tag.attr ){
				attrs ~= new Tree( "@" , "" , [ new Tree( key , val ) ] );
			}
			auto childs = el.items.map!( Tree.fromXML ).filter!( a => a ).array;
			return new Tree( el.tag.name , "" , attrs ~ childs );
		}

		auto com = cast( Comment ) xml;
		if( com ) {
			return new Tree( "--" , com.to!string[ 4 .. $ - 3 ] , [] );
		}

		auto txt = cast( Text ) xml;
		if( txt ) {
			if( txt.to!string.all!( isSpace ) ) return null;
			return new Tree( "'" , com.to!string , [] );
		}

		throw new Error( "Unsupported node type!" );
	}

	OutputType pipe(
		OutputType
	) (
		OutputType output ,
		string prefix = ""
	) {
		if( this.name.length ) output.write( this.name ~ " " );

		auto chunks = this.value.length ? this.value.split( "\n" ) : [];

		if( chunks.length + this.childs.length == 1 ) {
			if( chunks.length ) output.write( "\\" ~ chunks[0] ~ "\n" );
			else childs[0].pipe( output , prefix );
		} else {
			output.write( "\n" );
			if( this.name.length ) prefix ~= "\t";

			foreach( chunk ; chunks ) output.write( prefix ~ "\\" ~ chunk ~ "\n" );

			foreach( child ; this.childs ) {
				output.write( prefix );
				child.pipe( output , prefix );
			}
		}

		return output;
	}

	override string toString() {
		OutBuffer buf = new OutBuffer;
		this.pipe( buf );
		return buf.to!string;
	}

	Tree expand() {
		return this.make( null , null , [ new Tree( "@" , this.uri , [] ) ] ~ this.childs.map!( child => child.expand ).array );
	}

	string uri( ) {
		return this.baseUri ~ "#" ~ this.row.to!string ~ ":" ~ this.col.to!string;
	}

	unittest {
		auto tree = new Tree( "foo \\1\nbar \\2" , "" );
		assert( tree["bar"][0].to!string == "bar \\2\n" );
	}
	auto opIndex( string path ) {
		return this[ path.split( " " ) ];
	}

	unittest {
		assert( new Tree( "foo bar \\2" , "" )[ [ "foo" , "bar" ] ].to!string == "bar \\2\n" );
	}
	auto opIndex( string[] path ) {
		Tree[] next = [ this ];
		foreach( string name ; path ) {
			if( !next.length ) break;
			Tree[] prev = next;
			next = [];
			foreach( Tree item ; prev ) {
				foreach( Tree child ; item.childs ) {
					if( child.name != name ) continue;
					next ~= child;
				}
			}
		}
		return new Tree( "" , "" , next );
	}

	Tree opIndex( size_t index ) {
		return this.childs[ index ];
	}

	Tree[] opSlice( size_t start , size_t end ) {
		return this.childs[ start .. end ];
	}

	size_t length( ) {
		return this.childs.length;
	}

	size_t opDollar( ) {
		return this.childs.length;
	}

}

string take( ref string input , string symbols ) {
	auto i = 0;
	while( i < input.length ) {
		auto symbol = input[i];
		if( symbols.indexOf( symbol ) == -1 ) {
			break;
		} else {
			i += 1;
		}
	}
	auto res = input[ 0 .. i ];
	input = input[ i .. $ ];
	return res;
}

string takeUntil( ref string input , string symbols ) {
	auto i = 0;
	while( i < input.length ) {
		auto symbol = input[i];
		if( symbols.indexOf( symbol ) == -1 ) {
			i += 1;
		} else {
			break;
		}
	}
	auto res = input[ 0 .. i ];
	input = input[ i .. $ ];
	return res;
}
