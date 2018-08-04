unit RakNetStatistics;

interface

type
  IRakNetStatistics = Interface(IInterface)
//    /// For each type in RNSPerSecondMetrics, what is the value over the last 1 second?
//    uint64_t valueOverLastSecond[RNS_PER_SECOND_METRICS_COUNT];
//
//    /// For each type in RNSPerSecondMetrics, what is the total value over the lifetime of the connection?
//    uint64_t runningTotal[RNS_PER_SECOND_METRICS_COUNT];
//
//    /// When did the connection start?
//    /// \sa RakNet::GetTimeUS()
//    RakNet::TimeUS connectionStartTime;
//
//    /// Is our current send rate throttled by congestion control?
//    /// This value should be true if you send more data per second than your bandwidth capacity
//    bool isLimitedByCongestionControl;
//
//    /// If \a isLimitedByCongestionControl is true, what is the limit, in bytes per second?
//    uint64_t BPSLimitByCongestionControl;
//
//    /// Is our current send rate throttled by a call to RakPeer::SetPerConnectionOutgoingBandwidthLimit()?
//    bool isLimitedByOutgoingBandwidthLimit;
//
//    /// If \a isLimitedByOutgoingBandwidthLimit is true, what is the limit, in bytes per second?
//    uint64_t BPSLimitByOutgoingBandwidthLimit;
//
//    /// For each priority level, how many messages are waiting to be sent out?
//    unsigned int messageInSendBuffer[NUMBER_OF_PRIORITIES];
//
//    /// For each priority level, how many bytes are waiting to be sent out?
//    double bytesInSendBuffer[NUMBER_OF_PRIORITIES];
//
//    /// How many messages are waiting in the resend buffer? This includes messages waiting for an ack, so should normally be a small value
//    /// If the value is rising over time, you are exceeding the bandwidth capacity. See BPSLimitByCongestionControl
//    unsigned int messagesInResendBuffer;
//
//    /// How many bytes are waiting in the resend buffer. See also messagesInResendBuffer
//    uint64_t bytesInResendBuffer;
//
//    /// Over the last second, what was our packetloss? This number will range from 0.0 (for none) to 1.0 (for 100%)
//    float packetlossLastSecond;
//
//    /// What is the average total packetloss over the lifetime of the connection?
//    float packetlossTotal;
//
//    RakNetStatistics& operator +=(const RakNetStatistics& other)
//    {
//      unsigned i;
//      for (i=0; i < NUMBER_OF_PRIORITIES; i++)
//      {
//        messageInSendBuffer[i]+=other.messageInSendBuffer[i];
//        bytesInSendBuffer[i]+=other.bytesInSendBuffer[i];
//      }
//
//      for (i=0; i < RNS_PER_SECOND_METRICS_COUNT; i++)
//      {
//        valueOverLastSecond[i]+=other.valueOverLastSecond[i];
//        runningTotal[i]+=other.runningTotal[i];
//      }
//
//      return *this;
//    }
//  };
  end;


implementation

end.
