import 'package:flutter/material.dart';
import 'package:app_ipx_esp_ddd/domain/models/vista.dart';

class ExpandableMenu extends StatefulWidget {
  final List<Vista> menuItems;
  final Function(Vista) onItemSelected;
  final int? selectedItemId;
  final bool useGradients;
  final bool useBlurEffects;
  
  const ExpandableMenu({
    Key? key, 
    required this.menuItems,
    required this.onItemSelected,
    this.selectedItemId,
    this.useGradients = true,
    this.useBlurEffects = false,
  }) : super(key: key);

  @override
  State<ExpandableMenu> createState() => _ExpandableMenuState();
}

class _ExpandableMenuState extends State<ExpandableMenu> with TickerProviderStateMixin {
  // Mapa para controlar qué elementos están expandidos
  Map<int, bool> _expandedItems = {};
  
  // Para efectos de hover
  int? _hoveredItemId;
  
  // Controladores de animación
  late final AnimationController _expandController;
  Map<int, AnimationController> _itemAnimations = {};
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar controlador principal
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Expandir automáticamente los items raíz (nivel 1)
    _autoExpandRootItems();
    
    // Auto-expandir elementos que contienen el item seleccionado
    _autoExpandParents();
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    _itemAnimations.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Obtener o crear un controlador de animación para un ítem específico
  AnimationController _getItemController(int itemId) {
    if (!_itemAnimations.containsKey(itemId)) {
      _itemAnimations[itemId] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
    return _itemAnimations[itemId]!;
  }

  void _autoExpandRootItems() {
    for (var item in widget.menuItems) {
      // Expandir solo los elementos de nivel superior
      if (item.esRaiz == 1) {
        _expandedItems[item.codVista] = true;
      }
    }
  }
  
  @override
  void didUpdateWidget(ExpandableMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItemId != oldWidget.selectedItemId) {
      _autoExpandParents();
    }
  }
  
  void _autoExpandParents() {
    if (widget.selectedItemId != null) {
      // Buscar y expandir padres del item seleccionado
      _expandParentOf(widget.menuItems, widget.selectedItemId!);
    }
  }
  
  // Función recursiva para encontrar y expandir los padres del item seleccionado
  bool _expandParentOf(List<Vista> items, int targetId) {
    for (var item in items) {
      if (item.codVista == targetId) {
        return true;
      }
      
      if (item.items != null && item.items!.isNotEmpty) {
        bool foundInChildren = _expandParentOf(item.items!, targetId);
        if (foundInChildren) {
          // Si se encontró el objetivo en los hijos, expandir este item
          _expandedItems[item.codVista] = true;
          return true;
        }
      }
    }
    return false;
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: widget.menuItems.length,
          itemBuilder: (context, index) {
            final item = widget.menuItems[index];
            
            // Crear una animación de entrada para cada ítem del menú
            final itemController = _getItemController(item.codVista);
            if (!itemController.isCompleted) {
              Future.delayed(Duration(milliseconds: 30 * index), () {
                if (mounted) itemController.forward();
              });
            }
            
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
                parent: itemController,
                curve: Curves.easeOut,
              )),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-0.05, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: itemController,
                  curve: Curves.easeOutCubic,
                )),
                child: _buildMenuItem(item, 0),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildMenuItem(Vista item, int level) {
    bool hasChildren = item.items != null && item.items!.isNotEmpty;
    bool isExpanded = _expandedItems[item.codVista] ?? false;
    bool isSelected = widget.selectedItemId == item.codVista;
    bool isHovered = _hoveredItemId == item.codVista;
    
    // Determinar colores según tema
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Crear paleta de colores dinámica
    final selectedBgColor = colorScheme.primaryContainer.withOpacity(0.15);
    final hoveredBgColor = colorScheme.primaryContainer.withOpacity(0.08);
    final primaryColor = colorScheme.primary;
    
    // Efectos de gradiente (opcional)
    Gradient? itemGradient;
    if (widget.useGradients) {
      if (isSelected && !hasChildren) {
        itemGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            selectedBgColor.withOpacity(0.5),
            selectedBgColor.withOpacity(0.3),
          ],
        );
      } else if (isHovered) {
        itemGradient = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            hoveredBgColor.withOpacity(0.4),
            hoveredBgColor.withOpacity(0.2),
          ],
        );
      }
    }
    
    // Determinar qué icono usar basado en la estructura del elemento
    IconData iconData = level == 0
        ? _getCategoryIcon(item.label)
        : hasChildren
            ? Icons.folder
            : item.icon != null && item.icon!.isNotEmpty
                ? _getIconForString(item.icon!)
                : Icons.description_outlined;
    
    // Determinar colores de iconos y texto
    final iconColor = isSelected
        ? primaryColor
        : hasChildren
            ? colorScheme.onSurfaceVariant
            : colorScheme.primary.withOpacity(0.75);
    
    final textColor = isSelected
        ? primaryColor
        : hasChildren
            ? colorScheme.onSurface
            : colorScheme.onSurface.withOpacity(0.9);
    
    // Aplicar indentación basada en el nivel
    double leftPadding = 16.0 * level;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado de categoría para elementos de nivel 0
        if (level == 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    primaryColor.withOpacity(0.15),
                    primaryColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    iconData,
                    size: 18,
                    color: primaryColor.withOpacity(0.8),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    item.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor.withOpacity(0.9),
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Elemento del menú con efectos mejorados
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredItemId = item.codVista),
          onExit: (_) => setState(() => _hoveredItemId = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(
              left: level == 0 ? 8.0 : leftPadding, 
              right: 8.0, 
              bottom: 2.0
            ),
            decoration: BoxDecoration(
              gradient: itemGradient,
              color: itemGradient == null 
                  ? (isSelected 
                      ? selectedBgColor 
                      : (isHovered 
                          ? hoveredBgColor 
                          : Colors.transparent))
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected && !hasChildren
                  ? Border.all(color: primaryColor.withOpacity(0.2), width: 1)
                  : null,
              boxShadow: isSelected || isHovered
                  ? [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      )
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                splashColor: primaryColor.withOpacity(0.1),
                highlightColor: Colors.transparent,
                onTap: () {
                  if (hasChildren) {
                    setState(() {
                      _expandedItems[item.codVista] = !isExpanded;
                    });
                  } else {
                    widget.onItemSelected(item);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: level == 0 ? 10.0 : 8.0,
                    horizontal: 4.0
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12.0),
                      
                      // Icono con contenedor decorativo
                      if (level > 0)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.1)
                                : isHovered
                                    ? primaryColor.withOpacity(0.05)
                                    : colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Icon(
                              iconData, 
                              size: 16,
                              color: iconColor,
                            ),
                          ),
                        ),
                      
                      if (level > 0) 
                        const SizedBox(width: 12.0),
                      
                      // Título del elemento con animación sutil
                      Expanded(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontSize: level == 0 ? 15 : 14,
                            fontWeight: isSelected 
                                ? FontWeight.w600 
                                : (hasChildren ? FontWeight.w500 : FontWeight.normal),
                            color: textColor,
                            letterSpacing: isSelected ? 0.2 : 0.1,
                          ),
                          child: Text(item.label),
                        ),
                      ),
                      
                      // Contador o badge (ejemplo)
                      if (!hasChildren && level > 0 && _shouldShowBadge(item))
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colorScheme.tertiary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getBadgeCount(item),
                            style: TextStyle(
                              color: colorScheme.onTertiary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      
                      // Indicador para elementos expandibles
                      if (hasChildren)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCirc,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isHovered || isSelected 
                                ? primaryColor.withOpacity(0.1) 
                                : colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCirc,
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: isSelected || isHovered
                                  ? primaryColor
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      // Indicador para elementos navegables
                      else if (level > 0 && !_shouldShowBadge(item))
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected 
                                ? primaryColor
                                : colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                        ),
                        
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Elementos hijos con animación mejorada
        if (hasChildren)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            child: isExpanded
                ? Container(
                    margin: const EdgeInsets.only(top: 4.0, bottom: 4.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: item.items!.length,
                      itemBuilder: (context, index) {
                        final childItem = item.items![index];
                        
                        // Animar la entrada de los items hijos
                        final delay = index * 50;
                        final animation = TweenSequence([
                          TweenSequenceItem(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            weight: 0.7,
                          ),
                        ]);
                        
                        return FutureBuilder(
                          future: Future.delayed(Duration(milliseconds: delay)),
                          builder: (context, snapshot) {
                            return AnimatedOpacity(
                              opacity: snapshot.connectionState == ConnectionState.done ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutQuart,
                              child: _buildMenuItem(childItem, level + 1),
                            );
                          },
                        );
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          
        // Separador con animación
        if (level == 0)
          TweenAnimationBuilder(
            tween: ColorTween(
              begin: colorScheme.outlineVariant.withOpacity(0.2),
              end: isSelected || isHovered 
                  ? primaryColor.withOpacity(0.1) 
                  : colorScheme.outlineVariant.withOpacity(0.3),
            ),
            duration: const Duration(milliseconds: 300),
            builder: (context, Color? color, _) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        color!,
                        color.withOpacity(0.5),
                        color.withOpacity(0.3),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  // Método para determinar si mostrar un badge en un ítem
  bool _shouldShowBadge(Vista item) {
    // Simplemente como ejemplo - puedes implementar tu lógica real aquí
    return false;
  }
  
  // Método para obtener el conteo del badge
  String _getBadgeCount(Vista item) {
    // Ejemplo - implementa tu lógica real
    return "3";
  }
  
  // Función para asignar iconos basados en el nombre de la categoría
  IconData _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    
    if (lowerCategory.contains('rrhh') || lowerCategory.contains('recursos')) {
      return Icons.people_alt_outlined;
    } else if (lowerCategory.contains('admin')) {
      return Icons.admin_panel_settings_outlined;
    } else if (lowerCategory.contains('venta')) {
      return Icons.point_of_sale_outlined;
    } else if (lowerCategory.contains('compra')) {
      return Icons.shopping_cart_outlined;
    } else if (lowerCategory.contains('reporte')) {
      return Icons.insert_chart_outlined;
    } else if (lowerCategory.contains('precio')) {
      return Icons.attach_money;
    } else if (lowerCategory.contains('comisio')) {
      return Icons.account_balance_wallet_outlined;
    } else if (lowerCategory.contains('pedido')) {
      return Icons.shopping_bag_outlined;
    } else if (lowerCategory.contains('tarea')) {
      return Icons.task_alt_outlined;
    } else if (lowerCategory.contains('producci')) {
      return Icons.precision_manufacturing_outlined;
    } else if (lowerCategory.contains('factura')) {
      return Icons.receipt_long_outlined;
    } else if (lowerCategory.contains('material')) {
      return Icons.inventory_2_outlined;
    } else if (lowerCategory.contains('entrega')) {
      return Icons.local_shipping_outlined;
    } else if (lowerCategory.contains('vehiculo') || lowerCategory.contains('vehículo')) {
      return Icons.directions_car_outlined;
    } else if (lowerCategory.contains('licita')) {
      return Icons.gavel_outlined;
    } else if (lowerCategory.contains('ficha')) {
      return Icons.badge_outlined;
    } else if (lowerCategory.contains('deposito') || lowerCategory.contains('depósito')) {
      return Icons.account_balance_outlined;
    } else if (lowerCategory.contains('libro')) {
      return Icons.menu_book_outlined;
    }
    
    return Icons.folder_outlined;
  }
  
  // Función para mapear strings de iconos a IconData
  IconData _getIconForString(String iconStr) {
    if (iconStr.contains("pi-circle")) {
      return Icons.radio_button_unchecked;
    } else if (iconStr.contains("home")) {
      return Icons.home_outlined;
    } else if (iconStr.contains("user") || iconStr.contains("person")) {
      return Icons.person_outline;
    } else if (iconStr.contains("chart")) {
      return Icons.insert_chart_outlined;
    } else if (iconStr.contains("settings")) {
      return Icons.settings_outlined;
    } else if (iconStr.contains("help")) {
      return Icons.help_outline;
    } else if (iconStr.contains("info")) {
      return Icons.info_outline;
    } else if (iconStr.contains("bell") || iconStr.contains("notification")) {
      return Icons.notifications_none;
    } else if (iconStr.contains("dollar") || iconStr.contains("money")) {
      return Icons.attach_money;
    } else if (iconStr.contains("shopping")) {
      return Icons.shopping_cart_outlined;
    } else if (iconStr.contains("file")) {
      return Icons.insert_drive_file_outlined;
    } else if (iconStr.contains("calendar")) {
      return Icons.calendar_today_outlined;
    } else if (iconStr.contains("location")) {
      return Icons.location_on_outlined;
    } else if (iconStr.contains("mail") || iconStr.contains("email")) {
      return Icons.mail_outline;
    } else if (iconStr.contains("search")) {
      return Icons.search;
    } else if (iconStr.contains("star")) {
      return Icons.star_outline;
    }
    
    return Icons.article_outlined;
  }
}