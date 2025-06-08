#include "chisock.bi"

namespace chi
	
	function socket.get_data _ 
		( _ 
			byval data_ as any ptr, _
			byval size as integer, _ 
			byval peek_only as integer _
		) as integer
		
		if( size <= 0 ) then
			exit function
		end if
		
		dim as socket_lock lock_ = p_recv_lock
		
		'' handle speed limits
		if( p_recv_limit > 0 ) then
			
			if( abs(timer-p_recv_timer) >= (1 / BUFF_RATE) ) then
				p_recv_timer = timer
				
				p_recv_accum -= (p_recv_limit / BUFF_RATE)
				
				if( p_recv_accum < 0 ) then p_recv_accum = 0
				
			end if
			
			if( p_recv_accum + size > p_recv_limit ) then
				
				if( p_recv_accum = p_recv_limit ) then exit function
				
				size = p_recv_limit - p_recv_accum
				
			end if
			
		end if
		
		'' update bytes/sec calc... reset counter
		if( abs(timer-p_recv_disp_timer) >= 1 ) then
			
			p_recv_rate = p_recv_accum
			p_recv_disp_timer = timer
			
			if( p_recv_limit = 0 ) then p_recv_accum = 0
			
		end if
		
		dim as integer available_data = length( )
		
		'' read data?
		if( size <= available_data ) then
			
			'' write to user pointer
			memcpy( data_, @p_recv_data[p_recv_caret], size )
			
			'' not peeking? update caret
			if( peek_only = FALSE ) then
				p_recv_caret += size
				p_recv_accum += size
			end if
			
			'' return bytes read
			function = size
			
		end if
		
	end function
	
	function socket.get_until _ 
		( _ 
			byref target as string _
		) as string
		
		dim as string res
		var tl = len(target), ins = 0
		
		do 
			sleep 1, 1
			var l = length( )
			if( l ) then
				
				var r_len = quick_len( res )
				var in_buffer = space(l)
				
				var gotten = get( in_buffer[0], l, , TRUE )
				quick_len( in_buffer ) = gotten
				
				res += in_buffer
				
				if( gotten > 0 ) then
					
					ins = instr( /'iif( tl >= r_len, 1, r_len - tl-1 ),'/ res, target )
					if( ins ) then
						quick_len( res ) = ins + tl - 1
						
						gotten = ins + tl - 1 - r_len
					end if
					
					dump_data( gotten )
				end if
				
				if( ins ) then exit do
				
			end if
			
			if( is_closed( ) ) then
				if( length( ) = 0 ) then
					exit do 
				end if
			end if
			
		loop
		
		function = res
		
	end function
	
	function socket.get_line _ 
		( _ 
		) as string
		
		var res = get_until( chr(13, 10) )
		function = left(res, len(res)-2)
		
	end function
	
	function socket.dump_data _ 
		( _ 
			byval size as integer _ 
		) as integer
		
		dim as socket_lock lock_ = p_recv_lock
		
		dim as integer available_data = length( )
		if( size <= available_data ) then
			p_recv_caret += size
			function = TRUE
		end if
		
	end function
	
end namespace