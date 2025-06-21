import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/publications_service.dart';
import '../services/content_moderation_service.dart';
import '../theme/app_colors.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int publicationId;
  final String publicationTitle;

  const CommentsBottomSheet({
    Key? key,
    required this.publicationId,
    required this.publicationTitle,
  }) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<Map<String, dynamic>> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final comments = await PublicationsService.getComments(widget.publicationId);
      
      // Reorganizar comentarios en estructura jerárquica correcta
      final organizedComments = _organizeCommentsHierarchy(List<Map<String, dynamic>>.from(comments));
      
      setState(() {
        _comments = organizedComments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar comentarios: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para filtrar comentarios duplicados
  List<Map<String, dynamic>> _filterDuplicateComments(List<Map<String, dynamic>> comments) {
    // Recopilar todos los IDs de comentarios que aparecen como respuestas
    Set<int> replyIds = <int>{};
    
    void collectReplyIds(List<dynamic>? replies) {
      if (replies != null) {
        for (var reply in replies) {
          replyIds.add(reply['id_comentario']);
          // Recursivamente recopilar IDs de respuestas anidadas
          collectReplyIds(reply['respuestas']);
        }
      }
    }
    
    // Recopilar todos los IDs de respuestas
    for (var comment in comments) {
      collectReplyIds(comment['respuestas']);
    }
    
    // Filtrar comentarios principales que no sean respuestas
    return comments.where((comment) => !replyIds.contains(comment['id_comentario'])).toList();
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final moderationResult = await ContentModerationService.analyzeText(commentText);
      
      if (!moderationResult.isAppropriate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Comentario rechazado: ${moderationResult.reason}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final replyingToId = _replyingToCommentId;
      
      final tempComment = {
        'id_comentario': DateTime.now().millisecondsSinceEpoch,
        'contenido_texto': commentText,
        'fecha_comentario': DateTime.now().toIso8601String(),
        'estado_revision': 'aprobado',
        'usuario': {
          'name': 'Tú', 
        },
        'id_comentario_padre': replyingToId,
        'respuestas': [],
      };

      setState(() {
        if (replyingToId != null) {
          _addReplyToComment(replyingToId, tempComment);
        } else {
          _comments.insert(0, tempComment);
        }
      });
      
      _commentController.clear();
      
      // Enviar al backend
      if (replyingToId != null) {
        print('🚀 Enviando respuesta al comentario $replyingToId');
        print('📝 Contenido: $commentText');
        print('🔍 _replyingToCommentId actual: $_replyingToCommentId');
        
        await PublicationsService.createReply(
          widget.publicationId,
          replyingToId,
          commentText,
        );
        print('✅ Respuesta enviada exitosamente');
      } else {
        print('🚀 Enviando comentario a la publicación ${widget.publicationId}');
        await PublicationsService.createComment(
          widget.publicationId,
          commentText,
        );
        print('✅ Comentario enviado exitosamente');
      }
      
      _cancelReply();
      
      // Recargar comentarios y mostrar mensaje de éxito
      await _loadComments();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(replyingToId != null ? 'Respuesta enviada exitosamente' : 'Comentario enviado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      print('❌ Error al enviar: $e');
      setState(() {
        if (_replyingToCommentId != null) {
          _removeReplyFromComment(_replyingToCommentId!, DateTime.now().millisecondsSinceEpoch);
        } else {
          _comments.removeWhere((comment) => 
            comment['id_comentario'] == DateTime.now().millisecondsSinceEpoch);
        }
      });
      
      String errorMessage = 'Error al enviar comentario';
      if (e.toString().contains('moderación') || e.toString().contains('Perspective')) {
        errorMessage = 'Error en la moderación de contenido. Intenta de nuevo.';
      } else if (e.toString().contains('No puedes comentar tu propia publicación')) {
        errorMessage = 'No puedes comentar directamente tu propia publicación.';
      } else if (e.toString().contains('No puedes responder a tu propio comentario')) {
        errorMessage = 'No puedes responder a tu propio comentario.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _addReplyToComment(int parentId, Map<String, dynamic> reply) {
    for (var comment in _comments) {
      if (comment['id_comentario'] == parentId) {
        if (comment['respuestas'] == null) {
          comment['respuestas'] = [];
        }
        comment['respuestas'].insert(0, reply);
        break;
      }
      if (comment['respuestas'] != null) {
        _addReplyToNestedComment(comment['respuestas'], parentId, reply);
      }
    }
  }

  void _addReplyToNestedComment(List<dynamic> replies, int parentId, Map<String, dynamic> reply) {
    for (var nestedReply in replies) {
      if (nestedReply['id_comentario'] == parentId) {
        if (nestedReply['respuestas'] == null) {
          nestedReply['respuestas'] = [];
        }
        nestedReply['respuestas'].insert(0, reply);
        break;
      }
      if (nestedReply['respuestas'] != null) {
        _addReplyToNestedComment(nestedReply['respuestas'], parentId, reply);
      }
    }
  }

  void _removeReplyFromComment(int parentId, int replyId) {
    for (var comment in _comments) {
      if (comment['id_comentario'] == parentId && comment['respuestas'] != null) {
        comment['respuestas'].removeWhere((reply) => reply['id_comentario'] == replyId);
        break;
      }
      if (comment['respuestas'] != null) {
        _removeReplyFromNestedComment(comment['respuestas'], parentId, replyId);
      }
    }
  }

  void _removeReplyFromNestedComment(List<dynamic> replies, int parentId, int replyId) {
    for (var nestedReply in replies) {
      if (nestedReply['id_comentario'] == parentId && nestedReply['respuestas'] != null) {
        nestedReply['respuestas'].removeWhere((reply) => reply['id_comentario'] == replyId);
        break;
      }
      if (nestedReply['respuestas'] != null) {
        _removeReplyFromNestedComment(nestedReply['respuestas'], parentId, replyId);
      }
    }
  }

  void _replyToComment(int commentId, String userName) {
      setState(() {
        // Usar siempre el ID del comentario específico al que se responde
        _replyingToCommentId = commentId;
        _replyingToUserName = userName;
      });
      
      // Hacer scroll hacia abajo para mostrar el campo de texto
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
      
      // Enfocar el campo de texto
      _commentController.clear();
      FocusScope.of(context).requestFocus(_focusNode);
  }

  void _cancelReply() {
    setState(() {
      _replyingToCommentId = null;
      _replyingToUserName = null;
    });
  }

  Widget _buildComment(Map<String, dynamic> comment, {int depth = 0}) {
    // Calcular margen dinámico que se reduce con la profundidad
    double leftMargin = depth > 0 ? (depth * 12.0).clamp(0.0, 48.0) : 0.0;
    
    // Reducir el tamaño de elementos en niveles profundos
    double avatarRadius = depth > 2 ? 12 : (depth > 0 ? 16 : 18);
    double fontSize = depth > 2 ? 11 : (depth > 0 ? 13 : 14);
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 6,
        left: leftMargin,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(depth > 2 ? 8 : 12),
            decoration: BoxDecoration(
              color: _getBackgroundColor(depth),
              borderRadius: BorderRadius.circular(depth > 2 ? 8 : 12),
              border: Border.all(
                color: _getBorderColor(depth),
                width: depth > 2 ? 0.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: avatarRadius,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (comment['usuario']?['name'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: avatarRadius * 0.75,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment['usuario']?['name'] ?? 'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: fontSize,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatDate(comment['fecha_comentario']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: fontSize - 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                if (comment['contenido_texto'] != null && comment['contenido_texto'].isNotEmpty)
                  Text(
                    comment['contenido_texto'],
                    style: TextStyle(
                      fontSize: fontSize,
                      height: 1.3,
                    ),
                  ),
                
                // Mostrar botón responder con límites de profundidad
                if (depth < 4) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () => _replyToComment(
                      comment['id_comentario'],
                      comment['usuario']?['name'] ?? 'Usuario',
                    ),
                    child: Text(
                      'Responder',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: fontSize - 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Renderizar respuestas con límite de profundidad
          if (comment['respuestas'] != null && 
              comment['respuestas'].isNotEmpty && 
              depth < 5)
            Column(
              children: [
                const SizedBox(height: 3),
                ...comment['respuestas'].map<Widget>((reply) => 
                  _buildComment(reply, depth: depth + 1)
                ).toList(),
              ],
            ),
      ],
    ),
  );
}

// Métodos auxiliares para colores dinámicos
Color _getBackgroundColor(int depth) {
  switch (depth) {
    case 0: return Colors.white;
    case 1: return Colors.grey[50]!;
    case 2: return Colors.grey[100]!;
    default: return Colors.grey[100]!;
  }
}

Color _getBorderColor(int depth) {
  switch (depth) {
    case 0: return Colors.grey[100]!;
    case 1: return Colors.grey[200]!;
    case 2: return Colors.grey[300]!;
    default: return Colors.grey[300]!;
  }
}

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Comentarios',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                        ? const Center(
                            child: Text(
                              'No hay comentarios aún\nSé el primero en comentar',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              return _buildComment(_comments[index]);
                            },
                          ),
              ),
              
              if (_replyingToCommentId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue[50],
                  child: Row(
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Respondiendo a $_replyingToUserName',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _cancelReply,
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: _replyingToCommentId != null 
                                ? 'Escribe una respuesta...'
                                : 'Escribe un comentario...',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          cursorColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _isSubmitting ? null : _submitComment,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                        splashRadius: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Método para organizar comentarios en jerarquía correcta
  List<Map<String, dynamic>> _organizeCommentsHierarchy(List<Map<String, dynamic>> comments) {
    // Crear un mapa para acceso rápido por ID
    Map<int, Map<String, dynamic>> commentMap = {};
    for (var comment in comments) {
      commentMap[comment['id_comentario']] = Map<String, dynamic>.from(comment);
      // Inicializar array de respuestas si no existe
      commentMap[comment['id_comentario']]!['respuestas'] = [];
    }
    
    // Lista para comentarios principales (sin padre)
    List<Map<String, dynamic>> rootComments = [];
    
    // Organizar comentarios en jerarquía
    for (var comment in comments) {
      int commentId = comment['id_comentario'];
      
      // Buscar si este comentario es respuesta de otro
      int? parentId = _findParentCommentId(commentId, comments);
      
      if (parentId != null && commentMap.containsKey(parentId)) {
        // Es una respuesta, agregarlo al padre
        commentMap[parentId]!['respuestas'].add(commentMap[commentId]!);
      } else {
        // Es un comentario principal
        rootComments.add(commentMap[commentId]!);
      }
    }
    
    return rootComments;
  }

  // Método para encontrar el ID del comentario padre
  int? _findParentCommentId(int commentId, List<Map<String, dynamic>> allComments) {
    // Buscar en todos los comentarios si este commentId aparece como respuesta
    for (var comment in allComments) {
      if (comment['respuestas'] != null) {
        for (var reply in comment['respuestas']) {
          if (reply['id_comentario'] == commentId) {
            return comment['id_comentario'];
          }
        }
      }
    }
    return null;
  }

  // Agregar el método _formatDate que falta
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Fecha no disponible';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) {
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      } else if (difference.inHours > 0) {
        return 'Hace ${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return 'Hace ${difference.inMinutes}m';
      } else {
        return 'Ahora';
      }
    } catch (e) {
      return 'Fecha inválida';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}