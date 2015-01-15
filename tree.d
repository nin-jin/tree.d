module jin.tree;

import std.string;
import std.conv;
import std.outbuffer;

class Tree {

	string name;
	private string _value;
	string uri;
	Tree[] childs;

	this( string name = "" , string value = "" , Tree[] childs = [] , string uri = "" ) {
		this.name = name;
		this._value = value;
		this.childs = childs;
		this.uri = uri;
	}

	static parse( string input , string uri = "" ) {
		auto root = new Tree;
		Tree[] stack = [ root ];

		uint row = 1;
		uint col = 1;

		Tree last = root;
		while( input.length ) {
			auto name = munch( input , "^ \t\n=" );
			if( name.length ) {
				auto next = new Tree( name , "" , [] , uri ~ "#" ~ to!string( row ) ~ ":" ~ to!string( col ) );
				col += name.length;
				last.childs ~= next;
				last = next;
				col += munch( input , " " ).length;
			} else {
				if( input[0] == '=' ) {
					auto value = munch( input , "^\n" )[1..$];
					auto next = new Tree( "" , value , [] , uri ~ "#" ~ to!string( row ) ~ ":" ~ to!string( col ) );
					last.childs ~= next;
					last = next;
				}
				row += munch( input , "\n" ).length;
				auto indent = munch( input , "\t" );
				col = indent.length;
				stack ~= last;
				stack.length = indent.length + 1;
				last = stack[$-1];
			}
		}

		return root;
	}

	OutputType pipe( OutputType )( OutputType output , string prefix = "" ) {
		if( this.name.length ) {
			if( !prefix.length ) {
				prefix = "\t";
			}
			output.write( this.name ~ " " );
			if( this.childs.length == 1 ) {
				this.childs[0].pipe( output , prefix );
				return output;
			}
			output.write( "\n" );
		} else if( this._value.length || prefix.length ) {
			output.write( "=" ~ this._value ~ "\n" );
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
		return new Tree( "" , "" , next );
	}

	Tree select( string path ) {
		return this.select( path.split( " " ) );
	}

	override string toString() {
		OutBuffer buf = new OutBuffer;
		this.pipe( buf );
		return buf.toString();
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

