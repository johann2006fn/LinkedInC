import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:screen_protector/screen_protector.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/antigravity_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../models/session.dart';
import '../providers/app_providers.dart';
import '../widgets/session_message_tile.dart';
import '../widgets/user_avatar.dart';
import '../models/app_user.dart';
import 'dart:ui';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatDetailScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _allowsVideo = false;
  bool _isUploading = false;

  String get _currentUserId => ref.read(currentUserProvider).value?.id ?? '';
  String get _otherUserId => widget.chat.participantIds.firstWhere(
    (id) => id != _currentUserId,
    orElse: () => '',
  );

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _enableScreenProtection();
    _checkVideoPreferences();
    _ensureChatDetails();
  }

  Future<void> _ensureChatDetails() async {
    if (widget.chat.participantIds.length < 2) {
      // This is a "skeleton" chat object from the router or incomplete
      try {
        final doc = await FirebaseFirestore.instance
            .collection('chats')
            .doc(widget.chat.id)
            .get();
        if (doc.exists && mounted) {
          final data = doc.data()!;
          final participants =
              (data['participantIds'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
          setState(() {
            widget.chat.participantIds.clear();
            widget.chat.participantIds.addAll(participants);
          });
          _checkVideoPreferences(); // Re-check now that we have the other ID
        }
      } catch (e) {
        debugPrint('Error fetching chat details: $e');
      }
    }
  }

  Future<void> _enableScreenProtection() async {
    await ScreenProtector.preventScreenshotOn();
  }

  Future<void> _checkVideoPreferences() async {
    if (_otherUserId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_otherUserId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        final prefs = data['preferences'] as Map<String, dynamic>?;
        if (mounted) {
          setState(() {
            _allowsVideo = prefs?['allowsVideo'] == true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking video preferences: $e');
    }
  }

  @override
  void dispose() {
    ScreenProtector.preventScreenshotOff();
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Optional: detect if user is near bottom to auto-scroll for new messages
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AntigravityTheme.midnightBlue,
        title: const Text('Clear Chat', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to clear all messages? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(chatRepositoryProvider).clearChat(widget.chat.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chat cleared')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to clear: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _sendMessage({
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentSize,
  }) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && attachmentUrl == null) return;

    final repo = ref.read(chatRepositoryProvider);
    _messageController.clear();

    // Auto-scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        curve: Curves.easeOut,
        duration: const Duration(milliseconds: 300),
      );
    }

    try {
      final msg = Message(
        id: '', // Generated by repo
        chatId: widget.chat.id,
        senderId: _currentUserId,
        content: text,
        timestamp: DateTime.now(),
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
      );
      await repo
          .sendMessage(widget.chat.id, msg)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isUploading = true);

        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileSize =
            '${(result.files.single.size / 1024 / 1024).toStringAsFixed(1)} MB';
        final extension =
            result.files.single.extension?.toUpperCase() ?? 'FILE';

        final storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_attachments')
            .child(widget.chat.id)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();

        await _sendMessage(
          attachmentUrl: downloadUrl,
          attachmentName: fileName,
          attachmentSize: '$fileSize • $extension',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (!mounted) return;
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _messageController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
    }
  }

  void _showProposeSessionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AntigravityTheme.midnightBlue,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Engagement Tools',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month,
                  color: AntigravityTheme.electricPurple,
                ),
              ),
              title: const Text(
                'Propose Mentorship Session',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                'Schedule a 1-on-1 with this professor',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showScheduleDialog();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.attach_file, color: Colors.white70),
              ),
              title: const Text(
                'Attach File',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _showScheduleDialog() async {
    final topicController = TextEditingController();
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AntigravityTheme.midnightBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Propose Mentorship Session',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: topicController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Discussion Topic',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'e.g. Research Paper Review',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.calendar_today,
                  color: AntigravityTheme.electricPurple,
                ),
                title: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : DateFormat('MMM d, yyyy').format(selectedDate!),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.access_time,
                  color: AntigravityTheme.electricPurple,
                ),
                title: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 19, minute: 0),
                  );
                  if (picked != null) setState(() => selectedTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                if (topicController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a topic')),
                  );
                  return;
                }
                if (selectedDate == null || selectedTime == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select date and time')),
                  );
                  return;
                }
                
                final combined = DateTime(
                  selectedDate!.year,
                  selectedDate!.month,
                  selectedDate!.day,
                  selectedTime!.hour,
                  selectedTime!.minute,
                );
                _sendSessionProposal(topicController.text, combined);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AntigravityTheme.electricPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Propose'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendSessionProposal(String topic, DateTime proposedTime) async {
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      final otherUser = await ref.read(otherUserProfileProvider(_otherUserId).future);
      if (otherUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find participant profile.')),
          );
        }
        return;
      }

      final mentorId = currentUser.role == 'mentor' ? currentUser.id : _otherUserId;

      // Conflict Check
      final conflictQuery = await FirebaseFirestore.instance
          .collection('sessions')
          .where('mentorId', isEqualTo: mentorId)
          .where('scheduledTime', isEqualTo: Timestamp.fromDate(proposedTime))
          .get();

      if (conflictQuery.docs.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This time slot is already booked'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final geminiChat = ref.read(geminiChatServiceProvider);
      // Don't let AI briefing block the message if it's slow
      final brief = await geminiChat
          .generatePreSessionBrief(widget.chat.id)
          .timeout(
            const Duration(seconds: 8),
            onTimeout: () => "AI analysis still processing...",
          );

      final isMentor = currentUser.role == 'mentor';
      final studentId = isMentor ? _otherUserId : currentUser.id;

      final msg = Message(
        id: '',
        chatId: widget.chat.id,
        senderId: currentUser.id,
        mentorId: mentorId,
        menteeId: studentId,
        menteeName: isMentor ? otherUser.name : currentUser.name,
        content:
            'Proposed a mentorship session: $topic at ${DateFormat('MMM d, h:mm a').format(proposedTime.toLocal())}',
        timestamp: DateTime.now(),
        type: MessageType.sessionProposal,
        metadata: {
          'sessionTopic': topic,
          'proposedTime': Timestamp.fromDate(proposedTime),
          'aiBrief': brief,
          'sessionStatus': 'proposed',
        },
      );

      await ref.read(chatRepositoryProvider).sendMessage(widget.chat.id, msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to propose: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _updateSessionStatus(
    Message message, {
    String? status,
    DateTime? newTime,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (status != null) {
        updates['metadata.sessionStatus'] = status;
      }
      if (newTime != null) {
        updates['metadata.proposedTime'] = Timestamp.fromDate(newTime);
      }

      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chat.id)
          .collection('messages')
          .doc(message.id)
          .update(updates);

      // Create session record if confirmed
      if (status == 'confirmed') {
        final currentUser = ref.read(currentUserProvider).value;
        final otherUser =
            ref.read(otherUserProfileProvider(_otherUserId)).value;

        if (currentUser != null && otherUser != null) {
          final isMentor = currentUser.role == 'mentor';
          final mentorId = isMentor ? currentUser.id : _otherUserId;
          final studentId = isMentor ? _otherUserId : currentUser.id;
          final mentorName = isMentor ? currentUser.name : otherUser.name;
          final studentName = isMentor ? otherUser.name : currentUser.name;

          final scheduledTime =
              newTime ??
              (message.metadata?['proposedTime'] as Timestamp?)?.toDate();

          if (scheduledTime != null) {
            final sessionId = await ref.read(sessionRepositoryProvider).createSession(
              Session(
                id: '',
                chatId: widget.chat.id,
                mentorId: mentorId,
                studentId: studentId,
                topic:
                    message.metadata?['sessionTopic'] as String? ??
                    'Mentorship Session',
                scheduledTime: scheduledTime,
                status: 'upcoming',
                mentorName: mentorName,
                studentName: studentName,
              ),
            );

            // Store the session ID in the message metadata for future reference (like ending call)
            await FirebaseFirestore.instance
                .collection('chats')
                .doc(widget.chat.id)
                .collection('messages')
                .doc(message.id)
                .update({'metadata.sessionId': sessionId});
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating session: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _sendSystemMessage(String content) async {
    try {
      final msg = Message(
        id: '',
        chatId: widget.chat.id,
        senderId: 'system',
        content: content,
        timestamp: DateTime.now(),
        type: MessageType.system,
      );
      await ref.read(chatRepositoryProvider).sendMessage(widget.chat.id, msg);
    } catch (e) {
      debugPrint('Error sending system message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesStream = ref.watch(chatMessagesProvider(widget.chat.id));

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AntigravityTheme.pureBlack,
        appBar: AppBar(
          backgroundColor: AntigravityTheme.pureBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: Consumer(
            builder: (context, ref, child) {
              final otherUserAsync = ref.watch(
                otherUserProfileProvider(_otherUserId),
              );
              return Row(
                children: [
                  otherUserAsync.when(
                    data: (user) => Stack(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AntigravityTheme.midnightBlue,
                          backgroundImage: user?.profileImageUrl != null
                              ? NetworkImage(user!.profileImageUrl!)
                              : null,
                          child: user?.profileImageUrl == null
                              ? Icon(
                                  (user?.role == 'mentor')
                                      ? Icons.engineering_rounded
                                      : Icons.school_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: user?.isOnline == true
                                  ? AntigravityTheme.neonGreen
                                  : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AntigravityTheme.pureBlack,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    loading: () => CircleAvatar(
                      radius: 20,
                      backgroundColor: AntigravityTheme.midnightBlue,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                    error: (error, stack) => CircleAvatar(
                      radius: 20,
                      backgroundColor: AntigravityTheme.midnightBlue,
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white54,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherUserAsync.when(
                            data: (user) => user?.name ?? 'User',
                            loading: () => '...',
                            error: (error, stack) => 'User',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            fontFamily: 'Outfit',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          otherUserAsync.when(
                            data: (user) =>
                                user?.availabilityStatus ??
                                (user?.isOnline == true ? 'ONLINE' : 'OFFLINE'),
                            loading: () => '...',
                            error: (error, stack) => 'OFFLINE',
                          ),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            if (_allowsVideo)
              IconButton(
                icon: const Icon(
                  Icons.videocam_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () async {
                  final currentUser = ref.read(currentUserProvider).value;
                  if (currentUser != null) {
                    await _sendSystemMessage('${currentUser.name} started a video call');
                    if (mounted) {
                      ref.read(videoCallServiceProvider).launchMeeting(
                            chatId: widget.chat.id,
                            userName: currentUser.name,
                            callerId: currentUser.id,
                            topic: "Mentorship Session with ${widget.chat.otherUserName}",
                          );
                    }
                  }
                },
              )
            else
              Tooltip(
                message: 'This mentor prefers text-only communication',
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 14, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Text only',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.info_outline_rounded, color: Colors.white, size: 22),
              onPressed: () async {
                final doc = await FirebaseFirestore.instance.collection('users').doc(_otherUserId).get();
                if (doc.exists && mounted) {
                   final user = AppUser.fromMap(doc.data()!, doc.id);
                   context.push('/mentor-detail', extra: user);
                }
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AntigravityTheme.midnightBlue,
              onSelected: (value) {
                if (value == 'clear') _clearChat();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 10),
                      Text('Clear Chat', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Stack(
          children: [
            // Ambient Background Glows
            Positioned(
              top: 100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Positioned(
              bottom: 200,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AntigravityTheme.neonGreen.withValues(alpha: 0.05),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: messagesStream.when(
                    data: (messages) {
                      final otherUser = ref.watch(otherUserProfileProvider(_otherUserId)).value;

                      // Scroll to bottom on load or new messages
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: false,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == _currentUserId;
                      final timeStr = DateFormat('h:mm a').format(msg.timestamp);

                      // Date grouping logic
                      bool showDateDivider = false;
                      if (index == 0) {
                        showDateDivider = true;
                      } else {
                        final previousMsg = messages[index - 1];
                        if (!_isSameDay(msg.timestamp, previousMsg.timestamp)) {
                          showDateDivider = true;
                        }
                      }

                      Widget messageWidget;

                      if (msg.attachmentUrl != null) {
                        messageWidget = Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildAttachmentMessage(
                            name: msg.attachmentName ?? 'File',
                            sizeLine: msg.attachmentSize ?? 'Unknown size',
                            isMe: isMe,
                            time: timeStr,
                          ),
                        );
                      } else if (msg.type == MessageType.sessionProposal) {
                        messageWidget = Consumer(
                          builder: (context, ref, child) {
                            final currentUser = ref.watch(currentUserProvider).value;
                            if (currentUser == null) return const SizedBox.shrink();

                            return SessionMessageTile(
                              message: msg,
                              isCurrentUserMentor: currentUser.role == 'mentor',
                              currentUserName: currentUser.name,
                              currentUserId: currentUser.id,
                              onConfirm: () => _updateSessionStatus(msg, status: 'confirmed'),
                              onCallStarted: () => _sendSystemMessage('[Call Started]'),
                              onCallEnded: (duration) => _sendSystemMessage('[Call Ended - Duration: $duration mins]'),
                              onReschedule: (newTime) => _updateSessionStatus(msg, status: 'rescheduled', newTime: newTime),
                            );
                          },
                        );
                      } else if (msg.type == MessageType.system) {
                        messageWidget = _buildSystemMessage(msg);
                      } else {
                        messageWidget = Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: isMe
                              ? _buildSentMessage(message: msg.content, time: timeStr)
                              : _buildReceivedMessage(
                                  message: msg.content,
                                  time: timeStr,
                                  user: otherUser,
                                ),
                        );
                      }

                      if (showDateDivider) {
                        return Column(
                          children: [
                            _buildDateDivider(msg.timestamp),
                            messageWidget,
                          ],
                        );
                      }
                      return messageWidget;
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AntigravityTheme.electricPurple,
                  ),
                ),
                error: (e, _) => Center(
                  child: Text(
                    'Error loading messages: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
            if (_isUploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AntigravityTheme.electricPurple,
                  ),
                ),
              ),
                _buildBottomInputArea(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceivedMessage({
    required String message,
    required String time,
    AppUser? user,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (user != null) ...[
            UserAvatar(user: user, radius: 16),
            const SizedBox(width: 8),
          ] else
            const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                    bottomLeft: Radius.circular(6),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                          bottomLeft: Radius.circular(6),
                        ),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white,
                          height: 1.5,
                          fontSize: 15,
                          fontFamily: 'Outfit',
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Text(
                    time,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.white10)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateDivider(date),
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  String _formatDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);

    if (msgDate == today) return 'TODAY';
    if (msgDate == yesterday) return 'YESTERDAY';
    return DateFormat('EEEE, MMM d').format(date).toUpperCase();
  }

  Widget _buildSystemMessage(Message msg) {
    final isVideoCall = msg.content.contains('video call');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isVideoCall 
                ? AntigravityTheme.electricPurple.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isVideoCall 
                  ? AntigravityTheme.electricPurple.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVideoCall ? Icons.videocam_rounded : Icons.info_outline,
                size: 16,
                color: isVideoCall ? AntigravityTheme.electricPurple : Colors.white24,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  msg.content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isVideoCall ? Colors.white : Colors.white38,
                    fontSize: 12,
                    fontWeight: isVideoCall ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentMessage({required String message, required String time}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AntigravityTheme.electricPurple,
                  const Color(0xFF6D28D9).withValues(alpha: 0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(22),
                topRight: Radius.circular(22),
                bottomLeft: Radius.circular(22),
                bottomRight: Radius.circular(6),
              ),
              boxShadow: [
                BoxShadow(
                  color: AntigravityTheme.electricPurple.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.1),
                  blurRadius: 0,
                  offset: const Offset(0, 0),
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                height: 1.5,
                fontSize: 15,
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.done_all,
                  color: AntigravityTheme.neonGreen,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMessage({
    required String name,
    required String sizeLine,
    required bool isMe,
    required String time,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            width: 250,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe
                  ? AntigravityTheme.electricPurple.withValues(alpha: 0.15)
                  : const Color(0xFF1E1E2A),
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(4),
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(4),
                    ),
              border: Border.all(
                  color: isMe
                      ? AntigravityTheme.electricPurple.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sizeLine,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.file_download_outlined,
                  color: isMe ? Colors.white : Colors.white60,
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: EdgeInsets.only(left: isMe ? 0 : 4, right: isMe ? 4 : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.done_all,
                    color: AntigravityTheme.neonGreen,
                    size: 14,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInputArea(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AntigravityTheme.pureBlack,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFF0D0B14).withValues(alpha: 0.8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Compact Action Bar
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInputIconButton(
                      icon: Icons.add_rounded,
                      onTap: _showProposeSessionOptions,
                    ),
                    const SizedBox(width: 8),
                    _buildInputIconButton(
                      icon: Icons.attach_file_rounded,
                      onTap: _pickAndUploadFile,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            maxLines: 5,
                            minLines: 1,
                            decoration: InputDecoration(
                              hintText: _isListening ? 'Listening...' : 'Type message...',
                              hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: _isListening ? Colors.redAccent : Colors.white24,
                            size: 20,
                          ),
                          onPressed: _listen,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _sendMessage(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AntigravityTheme.electricPurple, Color(0xFF6D28D9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputIconButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Icon(icon, color: Colors.white70, size: 22),
      ),
    );
  }
}
