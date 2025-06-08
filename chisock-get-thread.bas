#include "chisock.bi"

namespace chi
	
	sub socket.recv_proc( byval opaque as any ptr )
		dim as socket ptr this = opaque
		
		dim as integer res, standby
		dim as ubyte buffer_in(8191)
		
		do while( this->p_dead = FALSE )
			
			sleep 1, 1
			
			if( this->p_socket = SOCKET_ERROR ) then
				continue do
			end if
			
			scope
				dim as socket_lock lock_ = this->p_recv_lock
				
				'' reset caret?
				if( this->p_recv_size > 0 ) then
					if( this->p_recv_size = this->p_recv_caret ) then
						this->p_recv_size = 0
						this->p_recv_caret = 0
					end if
				end if
				
			end scope
			
			standby = FALSE
			
			'' select read method
			select case as const this->p_kind
			case SOCK_TCP, SOCK_UDP
				
				res = recv( this->p_socket, cast(any ptr, @buffer_in(0)), 8192, 0 )
				
			case SOCK_UDP_CONNECTIONLESS
				
				var l = len(this->p_recv_info)
				res = recvfrom( this->p_socket, cast(any ptr, @buffer_in(0)), 8192, 0, cast(sockaddr ptr, @this->p_recv_info), @l )
				
			end select
			
			'' close if necessary
			dim as integer do_close = FALSE
			select case as const this->p_kind
			case SOCK_TCP
				do_close = (res <= 0)
			end select
			
			if( do_close ) then
				this->close( )
			end if
			
			'' work to do?
			if( res <= 0 ) then
				standby = TRUE
			end if
			
			if( standby = FALSE ) then
				
				dim as socket_lock lock_ = this->p_recv_lock
				
				'' need more room?
				if( res > this->p_recv_buff_size - this->p_recv_size ) then
					
					this->p_recv_buff_size += res - ( this->p_recv_buff_size - this->p_recv_size )
					this->p_recv_data = reallocate( this->p_recv_data, this->p_recv_buff_size )
					
				end if
				
				'' write
				memcpy( @this->p_recv_data[this->p_recv_size], @buffer_in(0), res )
				this->p_recv_size += res
				
				'' trim to curb unnecessary growth
				if( this->p_recv_size > this->p_recv_buff_size\2 ) then
					
					dim as integer move_size = this->p_recv_size-this->p_recv_caret
					if( move_size < this->p_recv_buff_size ) then
						
						memmove( this->p_recv_data, @this->p_recv_data[this->p_recv_caret], move_size )
						this->p_recv_caret = 0
						this->p_recv_size = move_size
						
					end if
					
				end if
				
			end if
			
		loop
	end sub
	
end namespace
