import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../voice/driver/driver_voice_controller.dart';

class DriverCallScreen extends StatefulWidget {
  final DriverVoiceRideRequest rideRequest;

  const DriverCallScreen({super.key, required this.rideRequest});

  @override
  State<DriverCallScreen> createState() => _DriverCallScreenState();
}

class _DriverCallScreenState extends State<DriverCallScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDriverCall();
  }

  Future<void> _initializeDriverCall() async {
    // Simulate incoming call notification
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      // Start voice-guided ride request handling
      final driverVoice = context.read<DriverVoiceController>();
      await driverVoice.handleIncomingRideCall(widget.rideRequest);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Consumer<DriverVoiceController>(
        builder: (context, driverVoice, child) {
          return _buildCallInterface(driverVoice);
        },
      ),
    );
  }

  Widget _buildCallInterface(DriverVoiceController driverVoice) {
    switch (driverVoice.state) {
      case DriverVoiceState.receivingCall:
        return _buildIncomingCallUI();
      
      case DriverVoiceState.announcing:
        return _buildAnnouncingUI();
      
      case DriverVoiceState.waitingForDecision:
        return _buildWaitingForDecisionUI();
      
      case DriverVoiceState.rideAccepted:
        return _buildRideAcceptedUI();
      
      default:
        return _buildIncomingCallUI();
    }
  }

  Widget _buildIncomingCallUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // CUSTOMER AVATAR
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: const CircleAvatar(
              radius: 55,
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Solicitare Cursă',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 10),
          
          Text(
            widget.rideRequest.passengerName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          
          const SizedBox(height: 30),
          
          // RIDE DETAILS CARD
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withAlpha(77)),
            ),
            child: Column(
              children: [
                _buildRideDetailRow(
                  Icons.location_on, 
                  'Pickup', 
                  widget.rideRequest.pickupAddress
                ),
                const SizedBox(height: 12),
                _buildRideDetailRow(
                  Icons.flag, 
                  'Destinație', 
                  widget.rideRequest.destinationAddress
                ),
                const SizedBox(height: 12),
                _buildRideDetailRow(
                  Icons.attach_money, 
                  'Preț', 
                  '${widget.rideRequest.estimatedPrice.toStringAsFixed(0)} RON'
                ),
                const SizedBox(height: 12),
                _buildRideDetailRow(
                  Icons.timer, 
                  'Distanță', 
                  '${widget.rideRequest.distance.toStringAsFixed(1)} km'
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          const Text(
            'Pregătește-te să răspunzi vocal...',
            style: TextStyle(
              color: Colors.yellow,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.volume_up,
            size: 80,
            color: Colors.blue,
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Anunț Comandă',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(51),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.blue.withAlpha(128)),
            ),
            child: const Text(
              'Ascultați detaliile comenzii...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForDecisionUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // LISTENING ANIMATION
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withAlpha(51),
              border: Border.all(color: Colors.red, width: 3),
            ),
            child: const Icon(
              Icons.mic,
              size: 50,
              color: Colors.red,
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Vă Ascult',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(51),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.withAlpha(128)),
            ),
            child: const Column(
              children: [
                Text(
                  'Spuneți răspunsul:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '"ACCEPT" sau "REFUZ"',
                  style: TextStyle(
                    color: Colors.yellow,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // VISUAL BACKUP BUTTONS (optional fallback)
          Consumer<DriverVoiceController>(
            builder: (context, driverVoice, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: driverVoice.isProcessingAccept ? null : () {
                      driverVoice.acceptRide();
                    },
                    icon: driverVoice.isProcessingAccept 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      driverVoice.isProcessingAccept ? 'ACCEPT...' : 'ACCEPT', 
                      style: const TextStyle(color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      disabledBackgroundColor: Colors.green.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: driverVoice.isProcessingReject ? null : () {
                      driverVoice.rejectRide();
                    },
                    icon: driverVoice.isProcessingReject 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.close, color: Colors.white),
                    label: Text(
                      driverVoice.isProcessingReject ? 'REFUZ...' : 'REFUZ', 
                      style: const TextStyle(color: Colors.white)
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      disabledBackgroundColor: Colors.red.withValues(alpha: 0.6),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRideAcceptedUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle,
            size: 80,
            color: Colors.green,
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Cursă Acceptată!',
            style: TextStyle(
              color: Colors.green,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 20),
          
          const Text(
            'Începe navigația către client...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          
          const SizedBox(height: 30),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withAlpha(51),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.green.withAlpha(128)),
            ),
            child: const Column(
              children: [
                Text(
                  'Comenzi vocale disponibile:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  '• "Am ajuns la client"\n'
                  '• "Client a urcat"\n'
                  '• "Am ajuns la destinație"\n'
                  '• "Trimite mesaj"',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
