#include "chisock.bi"

#macro DEFINE_SOCKET_PUT(t)
	function socket.put _ 
		( _ 
			byref data_ as t, _
			byref elems as integer, _ 
			byval time_out as integer _
		) as integer
		
		if( is_closed( ) ) then
			exit function
		end if
		
		dim as integer chunk_ = elems*len(t), piece
		piece = this.put_data( @data_, chunk_ )
		
		function = TRUE
		
	end function
#endmacro

namespace chi
	
	DEFINE_SOCKET_PUT(short)
	DEFINE_SOCKET_PUT(integer)
	DEFINE_SOCKET_PUT(double )
	DEFINE_SOCKET_PUT(ubyte  )
	
	function socket.put _ 
		( _ 
			byref data_ as string, _
			byref elems as integer, _ 
			byval time_out as integer _ 
		) as integer
		
		if( is_closed( ) ) then
			exit function
		end if
		
		dim as double delay, t
		dim as integer hdr, no_block = (time_out = ONLY_ONCE), ok_time = (time_out > 0)
		dim as string ptr current = cast(string ptr, @data_)
		
		for i as integer = 0 to elems-1
			delay = time_out/1000
			
			t = timer
			this.put( len(*current), 1, iif(no_block, ONLY_ONCE, iif(ok_time, cint(delay * 1000), 0)) )
			delay -= timer-t
			if( (delay < 0) and ok_time ) then
				exit function
			end if
			
			t = timer
			this.put( (*current)[0], len(*current), iif(no_block, ONLY_ONCE, iif(ok_time, cint(delay * 1000), 0)) )
			delay -= timer-t
			if( (delay < 0) and ok_time ) then
				exit function
			end if
			
			current += 1
		next
		
		function = TRUE
	end function
	
end namespace