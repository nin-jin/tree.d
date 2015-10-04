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
	private string _value;
	string baseUri;
	size_t row;
	size_t col;
	Tree[] childs;

	this(
		 string name = "" ,
		 string value = "" ,
		 Tree[] childs = [] ,
		 string baseUri = "" ,
		 size_t row = 0 ,
		 size_t col = 0 
	) {
		this.name = name;
		this._value = value;
		this.childs = childs;
		this.baseUri = baseUri;
		this.row = row;
		this.col = col;
	}

	static Name(
		string name ,
		Tree[] childs = [] ,
		string baseUri = "" ,
		size_t row = 0 ,
		size_t col = 0
	) {
		return new Tree( name , "" , childs , baseUri , row , col );
	}

	static Values(
		T = string
	)(
		T value ,
		Tree[] childs = [] ,
		string baseUri = "" ,
		size_t row = 0 ,
		size_t col = 0
	) {
		auto chunks = value.to!string.split( '\n' );
		auto nodes = chunks.map!( chunk => new Tree( "" , chunk , [] , baseUri , row , col ) );
		nodes[ $ - 1 ].childs = childs;
		return nodes.array;
	}

	static Value(
		T = string
	)(
		T value ,
		Tree[] childs = [] ,
		string baseUri = "" ,
		size_t row = 0 ,
		size_t col = 0
	) {
		auto values = Tree.Values( value , [] , baseUri , row , col );
		auto res = values.length > 1
			? new Tree( "" , "" , values , baseUri , row , col )
			: values[0];
		res.childs ~= childs;
		return res;
	}

	static List(
		Tree[] childs ,
		string baseUri = "" ,
		size_t row = 0 ,
		size_t col = 0
	) {
		return new Tree( "" , "" , childs , baseUri , row , col );
	}

	Tree clone( Tree[] childs = [] ) {
		return new Tree( this.name , this.value , childs , this.baseUri , this.row , this.col );
	}

	static parse(
		DirEntry input ,
		string baseUri = null ,
		size_t row = 1 ,
		size_t col = 1
	) {
		if( !baseUri.length ) {
			baseUri = absolutePath( input.name );
		}
		return Tree.parse( cast( string ) read( input.name ) , baseUri , row , col );
	}

	static parse(
		File input ,
		string baseUri = null ,
		size_t row = 1 ,
		size_t col = 1
	) {
		if( !baseUri.length ) {
			baseUri = input.name.absolutePath.asNormalizedPath.array;
		}
		return Tree.parse( cast( string ) read( input.name ) , baseUri , row , col );
	}

	static parse(
		string input ,
		string baseUri = "" ,
		size_t row = 1 ,
		size_t col = 1
	) {
		auto root = new Tree( "" , "" , [] , baseUri , row , col );
		Tree[] stack = [ root ];

		Tree parent = root;
		while( input.length ) {

			auto name = input.takeUntil( "\t\n =" );
			if( name.length ) {
				auto next = Tree.Name( name , [] , baseUri , row , col );
				parent.childs ~= next;
				parent = next;
				col += name.length + input.take( " " ).length;
				continue;
			}
			if( !input.length ) break;

			if( input[0] == '=' ) {
				auto value = input.takeUntil( "\n" )[ 1 .. $ ];
				auto next = new Tree( "" , value , [] , baseUri , row , col );
				parent.childs ~= next;
				parent = next;
			}
			if( !input.length ) break;

			if( input[0] != '\n' ) {
				throw new Exception( "Unexpected symbol " ~ input[0] );
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

		return root;
	}

	unittest {
		assert( Tree.parse( "foo\nbar\n" ).length == 2 );
		assert( Tree.parse( "foo\nbar\n" )[1].name == "bar" );
		assert( Tree.parse( "foo\n\n\n" ).length == 1 );

		assert( Tree.parse( "=foo\n=bar\n" ).length == 2 );
		assert( Tree.parse( "=foo\n=bar\n" )[1].value == "bar" );

		assert( Tree.parse( "foo bar =pol" )[0][0][0].value == "pol" );
		assert( Tree.parse( "foo bar\n\t=pol\n\t=men" )[0][0][1].value == "men" );
	}

	static Tree fromJSON( string json ) {
		return Tree.fromJSON( parseJSON( json ) );
	}
	static Tree fromJSON( JSONValue json ) {
		switch( json.type ) {
			case JSON_TYPE.FALSE :
				return Tree.Name( "false" );
			case JSON_TYPE.TRUE :
				return Tree.Name( "true" );
			case JSON_TYPE.NULL :
				return Tree.Name( "null" );
			case JSON_TYPE.FLOAT :
				return Tree.Name( json.floating.to!string );
			case JSON_TYPE.INTEGER :
				return Tree.Name( json.integer.to!string );
			case JSON_TYPE.UINTEGER :
				return Tree.Name( json.uinteger.to!string );
			case JSON_TYPE.STRING :
				return Tree.Value( json.str );
			case JSON_TYPE.ARRAY :
				return Tree.Name( "list" , json.array.map!( json => Tree.fromJSON( json ) ).array );
			case JSON_TYPE.OBJECT :
				Tree[] childs = [];
				foreach( key , value ; json.object ) {
					childs ~= Tree.Value( key , [ Tree.Name( ":" , [ Tree.fromJSON( value ) ] ) ] );
				}
				return Tree.Name( "map" , childs );
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
				attrs ~= Tree.Name( "@" , [ Tree.Name( key , Tree.Values( val ) ) ] );
			}
			auto childs = el.items.map!( Tree.fromXML ).filter!( a => a ).array;
			return Tree.Name( el.tag.name , attrs ~ childs );
		}

		auto com = cast( Comment ) xml;
		if( com ) {
			return Tree.Name( "--" , Tree.Values( com.toString[ 4 .. $ - 3 ] ) );
		}

		auto txt = cast( Text ) xml;
		if( txt ) {
			if( txt.toString.all!( isSpace ) ) return null;
			return Tree.Value( txt );
		}

		throw new Error( "Unsupported node type!" );
	}

	OutputType pipe( OutputType )( OutputType output , string prefix = "" ) {
		if( this.name.length ) {
			if( !prefix.length ) {
				prefix = "\t";
			}
			output.write( this.name );
			output.write( " " );
			if( this.childs.length == 1 ) {
				this.childs[0].pipe( output , prefix );
				return output;
			}
			output.write( "\n" );
		} else if( this._value.length || prefix.length ) {
			output.write( "=" );
			output.write( this._value );
			output.write( "\n" );
		}
		foreach( Tree child ; this.childs ) {
			output.write( prefix );
			child.pipe( output , prefix ~ "\t" );
		}
		return output;
	}

	Tree select( string[] path ) {
		Tree[] next = [ this ];
		foreach( string name ; path ) {
			if( !next.length ) break;
			Tree[] prev = next;
			next = [];
			foreach( Tree item ; prev ) {
				foreach( Tree child ; item.childs ) {
					if( child.name == name ) {
						next ~= child;
					}
				}
			}
		}
		return Tree.List( next );
	}

	Tree select( string path ) {
		return this.select( path.split( " " ) );
	}

	override string toString() {
		OutBuffer buf = new OutBuffer;
		this.pipe( buf );
		return buf.toString();
	}

	Tree expand() {
		return this.clone([ Tree.Value( this.uri.relativePath , this.childs.map!( child => child.expand ).array ) ]);
	}

	string uri( ) {
		return this.baseUri ~ "#" ~ this.row.to!string ~ ":" ~ this.col.to!string;
	}

	T value( T = string )() {
		string[] values;
		foreach( Tree child ; this.childs ) {
			if( !child.name.length ) {
				values ~= child.value;
			}
		}
		return to!T( this._value ~ values.join( "\n" ) );
	}

	Tree opIndex( size_t index ) {
		return this.childs[ index ];
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
