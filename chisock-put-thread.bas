#include "chisock.bi"

namespace chi
	
	sub socket.send_proc( byval opaque as any ptr )
		dim as socket ptr this = opaque
		
		dim as integer res, standby, chunk_
		do while( this->p_dead = FALSE )
			
			sleep 1, 1
			
			if( this->p_hold = TRUE ) then 
				
				mutexlock( this->p_hold_lock )
				mutexunlock( this->p_hold_lock )
				
				mutexlock( this->p_go_lock )
				
				condsignal( this->p_hold_signal )
				
				condwait( this->p_go_signal, this->p_go_lock )
				
				mutexunlock( this->p_go_lock )
				
			end if
			
			if( this->p_socket = SOCKET_ERROR ) then continue do
			
			standby = FALSE
			
			'' send in chunks
			chunk_ = this->p_send_size-this->p_send_caret
			'chunk_ = iif( chunk_ > 1024, 1024, chunk_ )
			
			'' anything?
			if( chunk_ ) then
				
				'' send method
				select case as const this->p_kind
				case SOCK_TCP, SOCK_UDP
					
					res = send( this->p_socket, _ 
					            cast(any ptr, @this->p_send_data[this->p_send_caret]), _ 
					            chunk_, _ 
					            0 )
					
				case SOCK_UDP_CONNECTIONLESS
					
					'' send to destination (lock info...)
					if( this->p_send_info ) then
						
						var l = len(*(this->p_send_info))
						res = sendto( this->p_socket, _ 
						              cast(any ptr, @this->p_send_data[this->p_send_caret]), _ 
						              chunk_, _ 
						              0, cast(sockaddr ptr, this->p_send_info), l )
						
					end if
					
				end select
				
				dim as integer do_close = FALSE
				select case as const this->p_kind
				case SOCK_TCP
					do_close = (res <= 0)
				case SOCK_UDP
					do_close = (res = -1)
				end select
				
				if( do_close ) then
					
					this->p_send_size = 0
					this->p_send_caret = 0
					
					this->close( )
					
				end if
				
			else
				
				res = 0
				
			end if
			
			if( res <= 0 ) then
				standby = TRUE
			end if
			
			if( standby = FALSE ) then
				
				dim as socket_lock lock_ = this->p_send_lock
				
				'' update
				this->p_send_caret += res 
				
				'' caught up?
				if( this->p_send_caret = this->p_send_size ) then
					this->p_send_size  = 0
					this->p_send_caret = 0
				end if
				
			end if
			
		loop
		
	end sub
	
end namespace
