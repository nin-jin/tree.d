module jin.tree;

import std.string;
import std.conv;
import std.outbuffer;
import std.algorithm;
import std.array;

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
		auto chunks = ( cast(string) value ).split( '\n' );
		auto nodes = chunks.map!( chunk => new Tree( "" , chunk , [] , baseUri , row , col ) );
		nodes[ $-1 ].childs = childs;
		return nodes.array;
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

			auto indent = input.take( "\t" ).length;
			if( indent > stack.length ) {
				throw new Exception( "Too many TABs " ~ row.to!string ~ ":" ~ col.to!string );
			}
			col = indent + 1;
			row += 1;

			stack ~= parent;
			stack.length  = indent + 1;
			parent = stack[ indent ];
		}

		return root;
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

}

string take( ref string input , string symbols ) {
	auto res = "";
	while( input.length ) {
		auto symbol = input[0];
		if( symbols.indexOf( symbol ) == -1 ) {
			break;
		} else {
			res ~= symbol;
			input = input[ 1 .. $ ];
		}
	}
	return res;
}

string takeUntil( ref string input , string symbols ) {
	auto res = "";
	while( input.length ) {
		auto symbol = input[0];
		if( symbols.indexOf( symbol ) == -1 ) {
			res ~= symbol;
			input = input[ 1 .. $ ];
		} else {
			break;
		}
	}
	return res;
}
