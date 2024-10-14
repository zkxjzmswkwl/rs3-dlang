module rdconstants;

///
/// Seconds, 5 minutes.
///
__gshared const int TRACKER_TIMEOUT = 300;
///
/// 1 Second. 
///
__gshared const int TRACKER_FREQUENCY = 500;
///
/// Should never be changed from 127.0.0.1/localhost.
///
__gshared const string SERVER_IP = "127.0.0.1";
///
/// TODO: Needs to be dynamic if we're to support > 1 client.
///
__gshared const ushort SERVER_PORT = 6969;