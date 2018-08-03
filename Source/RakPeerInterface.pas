unit RakPeerInterface;

interface

uses
  RakNetTypes,
  RakNetTime,
  System.Generics.Collections;

type
  IRakPeerInterface = Interface(IInterface)
    ///Destructor
//    destructor Destroy;

    // --------------------------------------------------------------------------------------------Major Low Level Functions - Functions needed by most users--------------------------------------------------------------------------------------------
    /// \brief Starts the network threads, opens the listen port.
    /// \details You must call this before calling Connect().
    /// Multiple calls while already active are ignored.  To call this function again with different settings, you must first call Shutdown().
    /// \note Call SetMaximumIncomingConnections if you want to accept incoming connections
    /// \param[in] maxConnections The maximum number of connections between this instance of RakPeer and another instance of RakPeer. Required so the network can preallocate and for thread safety. A pure client would set this to 1.  A pure server would set it to the number of allowed clients.- A hybrid would set it to the sum of both types of connections
    /// \param[in] localPort The port to listen for connections on. On linux the system may be set up so thast ports under 1024 are restricted for everything but the root user. Use a higher port for maximum compatibility.
    /// \param[in] socketDescriptors An array of SocketDescriptor structures to force RakNet to listen on a particular IP address or port (or both).  Each SocketDescriptor will represent one unique socket.  Do not pass redundant structures.  To listen on a specific port, you can pass SocketDescriptor(myPort,0); such as for a server.  For a client, it is usually OK to just pass SocketDescriptor(); However, on the XBOX be sure to use IPPROTO_VDP
    /// \param[in] socketDescriptorCount The size of the \a socketDescriptors array.  Pass 1 if you are not sure what to pass.
    /// \param[in] threadPriority Passed to the thread creation routine. Use THREAD_PRIORITY_NORMAL for Windows. For Linux based systems, you MUST pass something reasonable based on the thread priorities for your application.
    /// \return RAKNET_STARTED on success, otherwise appropriate failure enumeration.
    function Startup(maxConnections: Word; socketDescriptors: TSocketDescriptor; socketDescriptorCount: Word; threadPriority: Integer = 99999): TStartupResult;

    /// If you accept connections, you must call this or else security will not be enabled for incoming connections.
    /// This feature requires more round trips, bandwidth, and CPU time for the connection handshake
    /// x64 builds require under 25% of the CPU time of other builds
    /// See the Encryption sample for example usage
    /// \pre Must be called while offline
    /// \pre LIBCAT_SECURITY must be defined to 1 in NativeFeatureIncludes.h for this function to have any effect
    /// \param[in] publicKey A pointer to the public key for accepting new connections
    /// \param[in] privateKey A pointer to the private key for accepting new connections
    /// \param[in] bRequireClientKey: Should be set to false for most servers.  Allows the server to accept a public key from connecting clients as a proof of identity but eats twice as much CPU time as a normal connection
    function InitializeSecurity(const publicKey: PChar; const privateKey: PChar; bRequireClientKey: Boolean = false): Boolean;

    /// Disables security for incoming connections.
    /// \note Must be called while offline
    procedure DisableSecurity;

    /// If secure connections are on, do not use secure connections for a specific IP address.
    /// This is useful if you have a fixed-address internal server behind a LAN.
    /// \note Secure connections are determined by the recipient of an incoming connection. This has no effect if called on the system attempting to connect.
    /// \param[in] ip IP address to add. * wildcards are supported.
    procedure AddToSecurityExceptionList(ip: PChar);

    /// Remove a specific connection previously added via AddToSecurityExceptionList
    /// \param[in] ip IP address to remove. Pass 0 to remove all IP addresses. * wildcards are supported.
    procedure RemoveFromSecurityExceptionList(ip: PChar);

    /// Checks to see if a given IP is in the security exception list
    /// \param[in] IP address to check.
    function IsInSecurityExceptionList(ip: PChar): Boolean;

    /// Sets how many incoming connections are allowed. If this is less than the number of players currently connected,
    /// no more players will be allowed to connect.  If this is greater than the maximum number of peers allowed,
    /// it will be reduced to the maximum number of peers allowed.
    /// Defaults to 0, meaning by default, nobody can connect to you
    /// \param[in] numberAllowed Maximum number of incoming connections allowed.
    procedure SetMaximumIncomingConnections(numberAllowed: Word);

    /// Returns the value passed to SetMaximumIncomingConnections()
    /// \return the maximum number of incoming connections, which is always <= maxConnections
    function GetMaximumIncomingConnections(): Word;

    /// Returns how many open connections there are at this time
    /// \return the number of open connections
    function NumberOfConnections(): Word;

    /// Sets the password incoming connections must match in the call to Connect (defaults to none). Pass 0 to passwordData to specify no password
    /// This is a way to set a low level password for all incoming connections.  To selectively reject connections, implement your own scheme using CloseConnection() to remove unwanted connections
    /// \param[in] passwordData A data block that incoming connections must match.  This can be just a password, or can be a stream of data. Specify 0 for no password data
    /// \param[in] passwordDataLength The length in bytes of passwordData
    procedure SetIncomingPassword(const passwordData: PChar; passwordDataLength: Integer);

    /// Gets the password passed to SetIncomingPassword
    /// \param[out] passwordData  Should point to a block large enough to hold the password data you passed to SetIncomingPassword()
    /// \param[in,out] passwordDataLength Maximum size of the array passwordData.  Modified to hold the number of bytes actually written
    procedure GetIncomingPassword(passwordData: PChar; passwordDataLength: Integer);

    /// \brief Connect to the specified host (ip or domain name) and server port.
    /// Calling Connect and not calling SetMaximumIncomingConnections acts as a dedicated client.
    /// Calling both acts as a true peer. This is a non-blocking connection.
    /// You know the connection is successful when GetConnectionState() returns IS_CONNECTED or Receive() gets a message with the type identifier ID_CONNECTION_REQUEST_ACCEPTED.
    /// If the connection is not successful, such as a rejected connection or no response then neither of these things will happen.
    /// \pre Requires that you first call Startup()
    /// \param[in] host Either a dotted IP address or a domain name
    /// \param[in] remotePort Which port to connect to on the remote machine.
    /// \param[in] passwordData A data block that must match the data block on the server passed to SetIncomingPassword.  This can be a string or can be a stream of data.  Use 0 for no password.
    /// \param[in] passwordDataLength The length in bytes of passwordData
    /// \param[in] publicKey The public key the server is using. If 0, the server is not using security. If non-zero, the publicKeyMode member determines how to connect
    /// \param[in] connectionSocketIndex Index into the array of socket descriptors passed to socketDescriptors in RakPeer::Startup() to send on.
    /// \param[in] sendConnectionAttemptCount How many datagrams to send to the other system to try to connect.
    /// \param[in] timeBetweenSendConnectionAttemptsMS Time to elapse before a datagram is sent to the other system to try to connect. After sendConnectionAttemptCount number of attempts, ID_CONNECTION_ATTEMPT_FAILED is returned. Under low bandwidth conditions with multiple simultaneous outgoing connections, this value should be raised to 1000 or higher, or else the MTU detection can overrun the available bandwidth.
    /// \param[in] timeoutTime How long to keep the connection alive before dropping it on unable to send a reliable message. 0 to use the default from SetTimeoutTime(UNASSIGNED_SYSTEM_ADDRESS);
    /// \return CONNECTION_ATTEMPT_STARTED on successful initiation. Otherwise, an appropriate enumeration indicating failure.
    /// \note CONNECTION_ATTEMPT_STARTED does not mean you are already connected!
    /// \note It is possible to immediately get back ID_CONNECTION_ATTEMPT_FAILED if you exceed the maxConnections parameter passed to Startup(). This could happen if you call CloseConnection() with sendDisconnectionNotificaiton true, then immediately call Connect() before the connection has closed.
    function Connect(const host: PChar; remotePort: Word; const passwordData: PChar; passwordDataLength: Integer; publicKey: TPublicKey; connectionSocketIndex: Word = 0; sendConnectionAttemptCount: Word = 12; timeBetweenSendConnectionAttemptsMS: Word = 500; timeoutTime: TimeMS = 0): TConnectionAttemptResult;

    /// \brief Connect to the specified host (ip or domain name) and server port, using a shared socket from another instance of RakNet
    /// \param[in] host Either a dotted IP address or a domain name
    /// \param[in] remotePort Which port to connect to on the remote machine.
    /// \param[in] passwordData A data block that must match the data block on the server passed to SetIncomingPassword.  This can be a string or can be a stream of data.  Use 0 for no password.
    /// \param[in] passwordDataLength The length in bytes of passwordData
    /// \param[in] socket A bound socket returned by another instance of RakPeerInterface
    /// \param[in] sendConnectionAttemptCount How many datagrams to send to the other system to try to connect.
    /// \param[in] timeBetweenSendConnectionAttemptsMS Time to elapse before a datagram is sent to the other system to try to connect. After sendConnectionAttemptCount number of attempts, ID_CONNECTION_ATTEMPT_FAILED is returned. Under low bandwidth conditions with multiple simultaneous outgoing connections, this value should be raised to 1000 or higher, or else the MTU detection can overrun the available bandwidth.
    /// \param[in] timeoutTime How long to keep the connection alive before dropping it on unable to send a reliable message. 0 to use the default from SetTimeoutTime(UNASSIGNED_SYSTEM_ADDRESS);
    /// \return CONNECTION_ATTEMPT_STARTED on successful initiation. Otherwise, an appropriate enumeration indicating failure.
    /// \note CONNECTION_ATTEMPT_STARTED does not mean you are already connected!
    function ConnectWithSocket(const host: PChar; remotePort: Word; const passwordData: PChar; passwordDataLength: Integer; socket: TRakNetSocket2; publicKey: IPublicKey = nill; sendConnectionAttemptCount: Word = 12; timeBetweenSendConnectionAttemptsMS: Word = 500; timeoutTime: TimeMS = 0): TConnectionAttemptResult;

    /// \brief Connect to the specified network ID (Platform specific console function)
    /// \details Does built-in NAt traversal
    /// \param[in] passwordData A data block that must match the data block on the server passed to SetIncomingPassword.  This can be a string or can be a stream of data.  Use 0 for no password.
    /// \param[in] passwordDataLength The length in bytes of passwordData
    //virtual bool Console2LobbyConnect( void *networkServiceId, const char *passwordData, int passwordDataLength )=0;

    /// \brief Stops the network threads and closes all connections.
    /// \param[in] blockDuration How long, in milliseconds, you should wait for all remaining messages to go out, including ID_DISCONNECTION_NOTIFICATION.  If 0, it doesn't wait at all.
    /// \param[in] orderingChannel If blockDuration > 0, ID_DISCONNECTION_NOTIFICATION will be sent on this channel
    /// \param[in] disconnectionNotificationPriority Priority to send ID_DISCONNECTION_NOTIFICATION on.
    /// If you set it to 0 then the disconnection notification won't be sent
    procedure Shutdown(blockDuration: Word; orderingChannel: Byte = 0; disconnectionNotificationPriority: PacketPriority = LOW_PRIORITY);

    /// Returns if the network thread is running
    /// \return true if the network thread is running, false otherwise
    function IsActive(): Boolean;

    /// Fills the array remoteSystems with the SystemAddress of all the systems we are connected to
    /// \param[out] remoteSystems An array of SystemAddress structures to be filled with the SystemAddresss of the systems we are connected to. Pass 0 to remoteSystems to only get the number of systems we are connected to
    /// \param[in, out] numberOfSystems As input, the size of remoteSystems array.  As output, the number of elements put into the array
    function GetConnectionList(remoteSystems: ISystemAddress; numberOfSystems: Word): Boolean;

    /// Returns the next uint32_t that Send() will return
    /// \note If using RakPeer from multiple threads, this may not be accurate for your thread. Use IncrementNextSendReceipt() in that case.
    /// \return The next uint32_t that Send() or SendList will return
    function GetNextSendReceipt(): UInt32;

    /// Returns the next uint32_t that Send() will return, and increments the value by one
    /// \note If using RakPeer from multiple threads, pass this to forceReceipt in the send function
    /// \return The next uint32_t that Send() or SendList will return
    function IncrementNextSendReceipt(): UInt32;

    /// Sends a block of data to the specified system that you are connected to.
    /// This function only works while connected
    /// The first byte should be a message identifier starting at ID_USER_PACKET_ENUM
    /// \param[in] data The block of data to send
    /// \param[in] length The size in bytes of the data to send
    /// \param[in] priority What priority level to send on.  See PacketPriority.h
    /// \param[in] reliability How reliability to send this data.  See PacketPriority.h
    /// \param[in] orderingChannel When using ordered or sequenced messages, what channel to order these on. Messages are only ordered relative to other messages on the same stream
    /// \param[in] systemIdentifier Who to send this packet to, or in the case of broadcasting who not to send it to.  Pass either a SystemAddress structure or a RakNetGUID structure. Use UNASSIGNED_SYSTEM_ADDRESS or to specify none
    /// \param[in] broadcast True to send this packet to all connected systems. If true, then systemAddress specifies who not to send the packet to.
    /// \param[in] forceReceipt If 0, will automatically determine the receipt number to return. If non-zero, will return what you give it.
    /// \return 0 on bad input. Otherwise a number that identifies this message. If \a reliability is a type that returns a receipt, on a later call to Receive() you will get ID_SND_RECEIPT_ACKED or ID_SND_RECEIPT_LOSS with bytes 1-4 inclusive containing this number
    function Send(const data: PChar; const length: Integer; priority: PacketPriority; reliability: PacketReliability; orderingChannel: Char; const systemIdentifier: AddressOrGUID; broadcast: Boolean; forceReceiptNumber: UInt32 = 0): UInt32;

    /// "Send" to yourself rather than a remote system. The message will be processed through the plugins and returned to the game as usual
    /// This function works anytime
    /// The first byte should be a message identifier starting at ID_USER_PACKET_ENUM
    /// \param[in] data The block of data to send
    /// \param[in] length The size in bytes of the data to send
    procedure SendLoopback(const data: PChar; const length: Integer);

    /// Sends a block of data to the specified system that you are connected to.  Same as the above version, but takes a BitStream as input.
    /// \param[in] bitStream The bitstream to send
    /// \param[in] priority What priority level to send on.  See PacketPriority.h
    /// \param[in] reliability How reliability to send this data.  See PacketPriority.h
    /// \param[in] orderingChannel When using ordered or sequenced messages, what channel to order these on. Messages are only ordered relative to other messages on the same stream
    /// \param[in] systemIdentifier Who to send this packet to, or in the case of broadcasting who not to send it to. Pass either a SystemAddress structure or a RakNetGUID structure. Use UNASSIGNED_SYSTEM_ADDRESS or to specify none
    /// \param[in] broadcast True to send this packet to all connected systems. If true, then systemAddress specifies who not to send the packet to.
    /// \param[in] forceReceipt If 0, will automatically determine the receipt number to return. If non-zero, will return what you give it.
    /// \return 0 on bad input. Otherwise a number that identifies this message. If \a reliability is a type that returns a receipt, on a later call to Receive() you will get ID_SND_RECEIPT_ACKED or ID_SND_RECEIPT_LOSS with bytes 1-4 inclusive containing this number
    /// \note COMMON MISTAKE: When writing the first byte, bitStream->Write((unsigned char) ID_MY_TYPE) be sure it is casted to a byte, and you are not writing a 4 byte enumeration.
    function Send(const bitStream: RakNet.IBitStream; priority: PacketPriority; reliability: PacketReliability; orderingChannel: Char; const systemIdentifier: AddressOrGUID; broadcast: Boolean; forceReceiptNumber: Uint32 = 0): Uint32;

    /// Sends multiple blocks of data, concatenating them automatically.
    ///
    /// This is equivalent to:
    /// RakNet::BitStream bs;
    /// bs.WriteAlignedBytes(block1, blockLength1);
    /// bs.WriteAlignedBytes(block2, blockLength2);
    /// bs.WriteAlignedBytes(block3, blockLength3);
    /// Send(&bs, ...)
    ///
    /// This function only works while connected
    /// \param[in] data An array of pointers to blocks of data
    /// \param[in] lengths An array of integers indicating the length of each block of data
    /// \param[in] numParameters Length of the arrays data and lengths
    /// \param[in] priority What priority level to send on.  See PacketPriority.h
    /// \param[in] reliability How reliability to send this data.  See PacketPriority.h
    /// \param[in] orderingChannel When using ordered or sequenced messages, what channel to order these on. Messages are only ordered relative to other messages on the same stream
    /// \param[in] systemIdentifier Who to send this packet to, or in the case of broadcasting who not to send it to. Pass either a SystemAddress structure or a RakNetGUID structure. Use UNASSIGNED_SYSTEM_ADDRESS or to specify none
    /// \param[in] broadcast True to send this packet to all connected systems. If true, then systemAddress specifies who not to send the packet to.
    /// \param[in] forceReceipt If 0, will automatically determine the receipt number to return. If non-zero, will return what you give it.
    /// \return 0 on bad input. Otherwise a number that identifies this message. If \a reliability is a type that returns a receipt, on a later call to Receive() you will get ID_SND_RECEIPT_ACKED or ID_SND_RECEIPT_LOSS with bytes 1-4 inclusive containing this number
    function SendList(const data: PChar; const lengths: Integer; const numParameters: Integer; priority: PacketPriority; reliability: PacketReliability; char orderingChannel, const AddressOrGUID systemIdentifier, bool broadcast, uint32_t forceReceiptNumber=0 ): UInt32;

    /// Gets a message from the incoming message queue.
    /// Use DeallocatePacket() to deallocate the message after you are done with it.
    /// User-thread functions, such as RPC calls and the plugin function PluginInterface::Update occur here.
    /// \return 0 if no packets are waiting to be handled, otherwise a pointer to a packet.
    /// \note COMMON MISTAKE: Be sure to call this in a loop, once per game tick, until it returns 0. If you only process one packet per game tick they will buffer up.
    /// sa RakNetTypes.h contains struct Packet
    function Receive(): IPacket;

    /// Call this to deallocate a message returned by Receive() when you are done handling it.
    /// \param[in] packet The message to deallocate.
    function DeallocatePacket(packet: IPacket): Boolean;

    /// Return the total number of connections we are allowed
    function GetMaximumNumberOfPeers(): Word;

    // -------------------------------------------------------------------------------------------- Connection Management Functions--------------------------------------------------------------------------------------------
    /// Close the connection to another host (if we initiated the connection it will disconnect, if they did it will kick them out).
    /// \param[in] target Which system to close the connection to.
    /// \param[in] sendDisconnectionNotification True to send ID_DISCONNECTION_NOTIFICATION to the recipient.  False to close it silently.
    /// \param[in] channel Which ordering channel to send the disconnection notification on, if any
    /// \param[in] disconnectionNotificationPriority Priority to send ID_DISCONNECTION_NOTIFICATION on.
    procedure CloseConnection(const target: AddressOrGUID; sendDisconnectionNotification: Boolean; orderingChannel: Byte = 0; disconnectionNotificationPriority: PacketPriority = LOW_PRIORITY );

    /// Returns if a system is connected, disconnected, connecting in progress, or various other states
    /// \param[in] systemIdentifier The system we are referring to
    /// \note This locks a mutex, do not call too frequently during connection attempts or the attempt will take longer and possibly even timeout
    /// \return What state the remote system is in
    function GetConnectionState(const systemIdentifier: AddressOrGUID): ConnectionState;

    /// Cancel a pending connection attempt
    /// If we are already connected, the connection stays open
    /// \param[in] target Which system to cancel
    procedure CancelConnectionAttempt(const target: ISystemAddress);

    /// Given a systemAddress, returns an index from 0 to the maximum number of players allowed - 1.
    /// \param[in] systemAddress The SystemAddress we are referring to
    /// \return The index of this SystemAddress or -1 on system not found.
    function GetIndexFromSystemAddress(const systemAddress: ISystemAddress): Integer;

    /// This function is only useful for looping through all systems
    /// Given an index, will return a SystemAddress.
    /// \param[in] index Index should range between 0 and the maximum number of players allowed - 1.
    /// \return The SystemAddress
    function GetSystemAddressFromIndex(index: Word): ISystemAddress;

    /// Same as GetSystemAddressFromIndex but returns RakNetGUID
    /// \param[in] index Index should range between 0 and the maximum number of players allowed - 1.
    /// \return The RakNetGUID
    function GetGUIDFromIndex(index: Word): RakNetGUID;

    /// Same as calling GetSystemAddressFromIndex and GetGUIDFromIndex for all systems, but more efficient
    /// Indices match each other, so \a addresses[0] and \a guids[0] refer to the same system
    /// \param[out] addresses All system addresses. Size of the list is the number of connections. Size of the list will match the size of the \a guids list.
    /// \param[out] guids All guids. Size of the list is the number of connections. Size of the list will match the size of the \a addresses list.
    procedure GetSystemList(addresses: TList<ISystemAddress>; guids: TList<RakNetGUID>);

    /// Bans an IP from connecting.  Banned IPs persist between connections but are not saved on shutdown nor loaded on startup.
    /// param[in] IP Dotted IP address. Can use * as a wildcard, such as 128.0.0.* will ban all IP addresses starting with 128.0.0
    /// \param[in] milliseconds how many ms for a temporary ban.  Use 0 for a permanent ban
    procedure AddToBanList(const IP: PChar; milliseconds: RakNet.TimeMS = 0);

    /// Allows a previously banned IP to connect.
    /// param[in] Dotted IP address. Can use * as a wildcard, such as 128.0.0.* will banAll IP addresses starting with 128.0.0
    procedure RemoveFromBanList(const IP: PChar);

    /// Allows all previously banned IPs to connect.
    procedure ClearBanList();

    /// Returns true or false indicating if a particular IP is banned.
    /// \param[in] IP - Dotted IP address.
    /// \return true if IP matches any IPs in the ban list, accounting for any wildcards. False otherwise.
    function IsBanned(const IP: PChar): Boolean;

    /// Enable or disable allowing frequent connections from the same IP adderss
    /// This is a security measure which is disabled by default, but can be set to true to prevent attackers from using up all connection slots
    /// \param[in] b True to limit connections from the same ip to at most 1 per 100 milliseconds.
    procedure SetLimitIPConnectionFrequency(b: Boolean);

    // --------------------------------------------------------------------------------------------Pinging Functions - Functions dealing with the automatic ping mechanism--------------------------------------------------------------------------------------------
    /// Send a ping to the specified connected system.
    /// \pre The sender and recipient must already be started via a successful call to Startup()
    /// \param[in] target Which system to ping
    procedure Ping(const target: ISystemAddress);

    /// Send a ping to the specified unconnected system. The remote system, if it is Initialized, will respond with ID_PONG followed by sizeof(RakNet::TimeMS) containing the system time the ping was sent.(Default is 4 bytes - See __GET_TIME_64BIT in RakNetTypes.h
    /// System should reply with ID_PONG if it is active
    /// \param[in] host Either a dotted IP address or a domain name.  Can be 255.255.255.255 for LAN broadcast.
    /// \param[in] remotePort Which port to connect to on the remote machine.
    /// \param[in] onlyReplyOnAcceptingConnections Only request a reply if the remote system is accepting connections
    /// \param[in] connectionSocketIndex Index into the array of socket descriptors passed to socketDescriptors in RakPeer::Startup() to send on.
    /// \return true on success, false on failure (unknown hostname)
    function Ping(const host: PChar; remotePort: Word; onlyReplyOnAcceptingConnections: Boolean; connectionSocketIndex: Byte = 0): Boolean;

    /// Returns the average of all ping times read for the specific system or -1 if none read yet
    /// \param[in] systemAddress Which system we are referring to
    /// \return The ping time for this system, or -1
    function GetAveragePing(const systemIdentifier: AddressOrGUID): Integer;

    /// Returns the last ping time read for the specific system or -1 if none read yet
    /// \param[in] systemAddress Which system we are referring to
    /// \return The last ping time for this system, or -1
    function GetLastPing(const systemIdentifier: AddressOrGUID): Integer;

    /// Returns the lowest ping time read or -1 if none read yet
    /// \param[in] systemAddress Which system we are referring to
    /// \return The lowest ping time for this system, or -1
    function GetLowestPing(const systemIdentifier: AddressOrGUID): Integer;

    /// Ping the remote systems every so often, or not. Can be called anytime.
    /// By default this is true. Recommended to leave on, because congestion control uses it to determine how often to resend lost packets.
    /// It would be true by default to prevent timestamp drift, since in the event of a clock spike, the timestamp deltas would no longer be accurate
    /// \param[in] doPing True to start occasional pings.  False to stop them.
    procedure SetOccasionalPing(doPing: Boolean);

    /// Return the clock difference between your system and the specified system
    /// Subtract GetClockDifferential() from a time returned by the remote system to get that time relative to your own system
    /// Returns 0 if the system is unknown
    /// \param[in] systemIdentifier Which system we are referring to
    function GetClockDifferential(const systemIdentifier: AddressOrGUID): RakNet.Time;

    // --------------------------------------------------------------------------------------------Static Data Functions - Functions dealing with API defined synchronized memory--------------------------------------------------------------------------------------------
    /// Sets the data to send along with a LAN server discovery or offline ping reply.
    /// \a length should be under 400 bytes, as a security measure against flood attacks
    /// \param[in] data a block of data to store, or 0 for none
    /// \param[in] length The length of data in bytes, or 0 for none
    /// \sa Ping.cpp
    procedure SetOfflinePingResponse(const data: PChar; const length: Word);

    /// Returns pointers to a copy of the data passed to SetOfflinePingResponse
    /// \param[out] data A pointer to a copy of the data passed to \a SetOfflinePingResponse()
    /// \param[out] length A pointer filled in with the length parameter passed to SetOfflinePingResponse()
    /// \sa SetOfflinePingResponse
    procedure GetOfflinePingResponse(data: PChar; length: Word);

    //--------------------------------------------------------------------------------------------Network Functions - Functions dealing with the network in general--------------------------------------------------------------------------------------------
    /// Return the unique address identifier that represents you or another system on the the network and is based on your local IP / port.
    /// \note Not supported by the XBOX
    /// \param[in] systemAddress Use UNASSIGNED_SYSTEM_ADDRESS to get your behind-LAN address. Use a connected system to get their behind-LAN address
    /// \param[in] index When you have multiple internal IDs, which index to return? Currently limited to MAXIMUM_NUMBER_OF_INTERNAL_IDS (so the maximum value of this variable is MAXIMUM_NUMBER_OF_INTERNAL_IDS-1)
    /// \return the identifier of your system internally, which may not be how other systems see if you if you are behind a NAT or proxy
    function GetInternalID(const systemAddress: ISystemAddress = UNASSIGNED_SYSTEM_ADDRESS; const index: Integer = 0): ISystemAddress;

    /// \brief Sets your internal IP address, for platforms that do not support reading it, or to override a value
    /// \param[in] systemAddress. The address to set. Use SystemAddress::FromString() if you want to use a dotted string
    /// \param[in] index When you have multiple internal IDs, which index to set?
    procedure SetInternalID(systemAddress: ISystemAddress; index: Integer = 0);

    /// Return the unique address identifier that represents you on the the network and is based on your externalIP / port
    /// (the IP / port the specified player uses to communicate with you)
    /// \param[in] target Which remote system you are referring to for your external ID.  Usually the same for all systems, unless you have two or more network cards.
    function GetExternalID(const target: SystemAddress): ISystemAddress;

    /// Return my own GUID
    function GetMyGUID(): RakNetGUID;

    /// Return the address bound to a socket at the specified index
    function GetMyBoundAddress(const socketIndex: Integer = 0): ISystemAddress;

    /// Get a random number (to generate a GUID)
    function Get64BitUniqueRandomNumber(): Uint64;

    /// Given a connected system, give us the unique GUID representing that instance of RakPeer.
    /// This will be the same on all systems connected to that instance of RakPeer, even if the external system addresses are different
    /// Currently O(log(n)), but this may be improved in the future. If you use this frequently, you may want to cache the value as it won't change.
    /// Returns UNASSIGNED_RAKNET_GUID if system address can't be found.
    /// If \a input is UNASSIGNED_SYSTEM_ADDRESS, will return your own GUID
    /// \pre Call Startup() first, or the function will return UNASSIGNED_RAKNET_GUID
    /// \param[in] input The system address of the system we are connected to
    function GetGuidFromSystemAddress(const input: ISystemAddress): RakNetGUID;

    /// Given the GUID of a connected system, give us the system address of that system.
    /// The GUID will be the same on all systems connected to that instance of RakPeer, even if the external system addresses are different
    /// Currently O(log(n)), but this may be improved in the future. If you use this frequently, you may want to cache the value as it won't change.
    /// If \a input is UNASSIGNED_RAKNET_GUID, will return UNASSIGNED_SYSTEM_ADDRESS
    /// \param[in] input The RakNetGUID of the system we are checking to see if we are connected to
    function GetSystemAddressFromGuid(const input: RakNetGUID): SystemAddress;

    /// Given the SystemAddress of a connected system, get the public key they provided as an identity
    /// Returns false if system address was not found or client public key is not known
    /// \param[in] input The RakNetGUID of the system
    /// \param[in] client_public_key The connected client's public key is copied to this address.  Buffer must be cat::EasyHandshake::PUBLIC_KEY_BYTES bytes in length.
    function GetClientPublicKeyFromSystemAddress(const input: ISystemAddress; client_public_key: PChar): Boolean;

    /// Set the time, in MS, to use before considering ourselves disconnected after not being able to deliver a reliable message.
    /// Default time is 10,000 or 10 seconds in release and 30,000 or 30 seconds in debug.
    /// Do not set different values for different computers that are connected to each other, or you won't be able to reconnect after ID_CONNECTION_LOST
    /// \param[in] timeMS Time, in MS
    /// \param[in] target Which system to do this for. Pass UNASSIGNED_SYSTEM_ADDRESS for all systems.
    procedure SetTimeoutTime(timeMS: RakNet.TimeMS; const target: ISystemAddress);

    /// \param[in] target Which system to do this for. Pass UNASSIGNED_SYSTEM_ADDRESS to get the default value
    /// \return timeoutTime for a given system.
    function GetTimeoutTime(const target: ISystemAddress): RakNet.TimeMS;

    /// Returns the current MTU size
    /// \param[in] target Which system to get this for.  UNASSIGNED_SYSTEM_ADDRESS to get the default
    /// \return The current MTU size
    function GetMTUSize(const target: ISystemAddress): Integer;

    /// Returns the number of IP addresses this system has internally. Get the actual addresses from GetLocalIP()
    function GetNumberOfAddresses(): Word;

    /// Returns an IP address at index 0 to GetNumberOfAddresses-1
    /// \param[in] index index into the list of IP addresses
    /// \return The local IP address at this index
    function GetLocalIP(index: Word): PChar;

    /// Is this a local IP?
    /// \param[in] An IP address to check, excluding the port
    /// \return True if this is one of the IP addresses returned by GetLocalIP
    function IsLocalIP( const char *ip ): Boolean;

    /// Allow or disallow connection responses from any IP. Normally this should be false, but may be necessary
    /// when connecting to servers with multiple IP addresses.
    /// \param[in] allow - True to allow this behavior, false to not allow. Defaults to false. Value persists between connections
    procedure AllowConnectionResponseIPMigration(allow: Boolean);

    /// Sends a one byte message ID_ADVERTISE_SYSTEM to the remote unconnected system.
    /// This will tell the remote system our external IP outside the LAN along with some user data.
    /// \pre The sender and recipient must already be started via a successful call to Initialize
    /// \param[in] host Either a dotted IP address or a domain name
    /// \param[in] remotePort Which port to connect to on the remote machine.
    /// \param[in] data Optional data to append to the packet.
    /// \param[in] dataLength length of data in bytes.  Use 0 if no data.
    /// \param[in] connectionSocketIndex Index into the array of socket descriptors passed to socketDescriptors in RakPeer::Startup() to send on.
    /// \return false if IsActive()==false or the host is unresolvable. True otherwise
    function AdvertiseSystem(const host: PChar; remotePort: Word; const data: PChar; dataLength: Integer; connectionSocketIndex: Word = 0): Boolean;

    /// Controls how often to return ID_DOWNLOAD_PROGRESS for large message downloads.
    /// ID_DOWNLOAD_PROGRESS is returned to indicate a new partial message chunk, roughly the MTU size, has arrived
    /// As it can be slow or cumbersome to get this notification for every chunk, you can set the interval at which it is returned.
    /// Defaults to 0 (never return this notification)
    /// \param[in] interval How many messages to use as an interval
    procedure SetSplitMessageProgressInterval(int interval);

    /// Returns what was passed to SetSplitMessageProgressInterval()
    /// \return What was passed to SetSplitMessageProgressInterval(). Default to 0.
    function GetSplitMessageProgressInterval(): Integer;

    /// Set how long to wait before giving up on sending an unreliable message
    /// Useful if the network is clogged up.
    /// Set to 0 or less to never timeout.  Defaults to 0.
    /// \param[in] timeoutMS How many ms to wait before simply not sending an unreliable message.
    procedure SetUnreliableTimeout(timeoutMS: RakNet.TimeMS);

    /// Send a message to host, with the IP socket option TTL set to 3
    /// This message will not reach the host, but will open the router.
    /// Used for NAT-Punchthrough
    procedure SendTTL(const host: PCHar; remotePort: Integer; ttl: Integer; connectionSocketIndex: Integer = 0);

    // -------------------------------------------------------------------------------------------- Plugin Functions--------------------------------------------------------------------------------------------
    /// \brief Attaches a Plugin interface to an instance of the base class (RakPeer or PacketizedTCP) to run code automatically on message receipt in the Receive call.
    /// If the plugin returns false from PluginInterface::UsesReliabilityLayer(), which is the case for all plugins except PacketLogger, you can call AttachPlugin() and DetachPlugin() for this plugin while RakPeer is active.
    /// \param[in] messageHandler Pointer to the plugin to attach.
    procedure AttachPlugin(plugin: IPluginInterface2);

    /// \brief Detaches a Plugin interface from the instance of the base class (RakPeer or PacketizedTCP) it is attached to.
    ///	\details This method disables the plugin code from running automatically on base class's updates or message receipt.
    /// If the plugin returns false from PluginInterface::UsesReliabilityLayer(), which is the case for all plugins except PacketLogger, you can call AttachPlugin() and DetachPlugin() for this plugin while RakPeer is active.
    /// \param[in] messageHandler Pointer to a plugin to detach.
    procedure DetachPlugin(messageHandler: IPluginInterface2 );

    // --------------------------------------------------------------------------------------------Miscellaneous Functions--------------------------------------------------------------------------------------------
    /// Put a message back at the end of the receive queue in case you don't want to deal with it immediately
    /// \param[in] packet The packet you want to push back.
    /// \param[in] pushAtHead True to push the packet so that the next receive call returns it.  False to push it at the end of the queue (obviously pushing it at the end makes the packets out of order)
    procedure PushBackPacket(packet: IPacket; pushAtHead: Boolean);

    /// \internal
    /// \brief For a given system identified by \a guid, change the SystemAddress to send to.
    /// \param[in] guid The connection we are referring to
    /// \param[in] systemAddress The new address to send to
    procedure ChangeSystemAddress(guid: RakNetGUID; const systemAddress: ISystemAddress);

    /// \returns a packet for you to write to if you want to create a Packet for some reason.
    /// You can add it to the receive buffer with PushBackPacket
    /// \param[in] dataSize How many bytes to allocate for the buffer
    /// \return A packet you can write to
    function AllocatePacket(unsigned dataSize): IPacket;

    /// Get the socket used with a particular active connection
    /// The smart pointer reference counts the RakNetSocket2 object, so the socket will remain active as long as the smart pointer does, even if RakNet were to shutdown or close the connection.
    /// \note This sends a query to the thread and blocks on the return value for up to one second. In practice it should only take a millisecond or so.
    /// \param[in] target Which system
    /// \return A smart pointer object containing the socket information about the socket. Be sure to check IsNull() which is returned if the update thread is unresponsive, shutting down, or if this system is not connected
    function GetSocket(const target: ISystemAddress): IRakNetSocket2;

    /// Get all sockets in use
    /// \note This sends a query to the thread and blocks on the return value for up to one second. In practice it should only take a millisecond or so.
    /// \param[out] sockets List of RakNetSocket2 structures in use. Sockets will not be closed until \a sockets goes out of scope
    procedure GetSockets(sockets: TList<RakNetSocket2>);
    procedure ReleaseSockets(sockets: TList<RakNetSocket2>);

    procedure WriteOutOfBandHeader(bitStream: RakNet.IBitStream);

    /// If you need code to run in the same thread as RakNet's update thread, this function can be used for that
    /// \param[in] _userUpdateThreadPtr C callback function
    /// \param[in] _userUpdateThreadData Passed to C callback function
    procedure SetUserUpdateThread(void (*_userUpdateThreadPtr)(RakPeerInterface *, void *), void *_userUpdateThreadData)=0;

    /// Set a C callback to be called whenever a datagram arrives
    /// Return true from the callback to have RakPeer handle the datagram. Return false and RakPeer will ignore the datagram.
    /// This can be used to filter incoming datagrams by system, or to share a recvfrom socket with RakPeer
    /// RNS2RecvStruct will only remain valid for the duration of the call
    /// If the incoming datagram is not from your game at all, it is a RakNet packet.
    /// If the incoming datagram has an IP address that matches a known address from your game, then check the first byte of data.
    /// For RakNet connected systems, the first bit is always 1. So for your own game packets, make sure the first bit is always 0.
    virtual void SetIncomingDatagramEventHandler( bool (*_incomingDatagramEventHandler)(RNS2RecvStruct *) )=0;

    // --------------------------------------------------------------------------------------------Network Simulator Functions--------------------------------------------------------------------------------------------
    /// Adds simulated ping and packet loss to the outgoing data flow.
    /// To simulate bi-directional ping and packet loss, you should call this on both the sender and the recipient, with half the total ping and packetloss value on each.
    /// You can exclude network simulator code with the _RELEASE #define to decrease code size
    /// \deprecated Use http://www.jenkinssoftware.com/forum/index.php?topic=1671.0 instead.
    /// \note Doesn't work past version 3.6201
    /// \param[in] packetloss Chance to lose a packet. Ranges from 0 to 1.
    /// \param[in] minExtraPing The minimum time to delay sends.
    /// \param[in] extraPingVariance The additional random time to delay sends.
    procedure ApplyNetworkSimulator(packetloss: single; minExtraPing: Word; extraPingVariance: Word);

    /// Limits how much outgoing bandwidth can be sent per-connection.
    /// This limit does not apply to the sum of all connections!
    /// Exceeding the limit queues up outgoing traffic
    /// \param[in] maxBitsPerSecond Maximum bits per second to send.  Use 0 for unlimited (default). Once set, it takes effect immedately and persists until called again.
    procedure SetPerConnectionOutgoingBandwidthLimit(maxBitsPerSecond: Word);

    /// Returns if you previously called ApplyNetworkSimulator
    /// \return If you previously called ApplyNetworkSimulator
    function IsNetworkSimulatorActive(): Boolean;

    // --------------------------------------------------------------------------------------------Statistical Functions - Functions dealing with API performance--------------------------------------------------------------------------------------------

    /// Returns a structure containing a large set of network statistics for the specified system.
    /// You can map this data to a string using the C style StatisticsToString() function
    /// \param[in] systemAddress: Which connected system to get statistics for
    /// \param[in] rns If you supply this structure, it will be written to it.  Otherwise it will use a static struct, which is not threadsafe
    /// \return 0 on can't find the specified system.  A pointer to a set of data otherwise.
    /// \sa RakNetStatistics.h
    function GetStatistics(const systemAddress: ISystemAddress; rns: IRakNetStatistics = 0): IRakNetStatistics;
    /// \brief Returns the network statistics of the system at the given index in the remoteSystemList.
    ///	\return True if the index is less than the maximum number of peers allowed and the system is active. False otherwise.
    function GetStatistics(const index: Word; rns: IRakNetStatistics): Boolean;
    /// \brief Returns the list of systems, and statistics for each of those systems
    /// Each system has one entry in each of the lists, in the same order
    /// \param[out] addresses SystemAddress for each connected system
    /// \param[out] guids RakNetGUID for each connected system
    /// \param[out] statistics Calculated RakNetStatistics for each connected system
    procedure GetStatisticsList(addresses: TList<SystemAddress>; guids: TList<RakNetGUID>; statistics: TList<RakNetStatistics>);

    /// \Returns how many messages are waiting when you call Receive()
    function GetReceiveBufferSize(): Word;

    // --------------------------------------------------------------------------------------------EVERYTHING AFTER THIS COMMENT IS FOR INTERNAL USE ONLY--------------------------------------------------------------------------------------------

    /// \internal
    // Call manually if RAKPEER_USER_THREADED==1 at least every 30 milliseconds.
    // updateBitStream should be:
    // 	BitStream updateBitStream( MAXIMUM_MTU_SIZE
    // #if LIBCAT_SECURITY==1
    //	+ cat::AuthenticatedEncryption::OVERHEAD_BYTES
    // #endif
    // );
    function RunUpdateCycle(updateBitStream: IBitStream): Boolean;

    /// \internal
    function SendOutOfBand(const host: PChar; remotePort: Word; const data: PChar; dataLength: BitSize_t; connectionSocketIndex: Word = 0): Boolean;
  end;

implementation

end.
