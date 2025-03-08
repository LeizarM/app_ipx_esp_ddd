import 'package:app_ipx_esp_ddd/domain/models/vista.dart';
import 'package:flutter/material.dart';

// Add import for ItemsViewStock
import 'package:app_ipx_esp_ddd/presentation/pages/items_view_stock/items_view_stock.dart';

class ExpandableMenu extends StatefulWidget {
  final List<Vista> menuItems;
  final Function(Vista) onItemSelected;
  final int? selectedItemId;
  final bool useGradients;
  final bool useBlurEffects;
  
  const ExpandableMenu({
    super.key, 
    required this.menuItems,
    required this.onItemSelected,
    this.selectedItemId,
    this.useGradients = true,
    this.useBlurEffects = false,
  });

  @override
  State<ExpandableMenu> createState() => _ExpandableMenuState();
}

class _ExpandableMenuState extends State<ExpandableMenu> with TickerProviderStateMixin {
  // Map to track expanded items
  final Map<int, bool> _expandedItems = {};
  
  // For hover effects
  int? _hoveredItemId;
  
  // Animation controllers
  late final AnimationController _expandController;
  final Map<int, AnimationController> _itemAnimations = {};
  
  // Filtered menu items
  late List<Vista> _filteredMenuItems;
  
  // Map of available pages in the project
  final Map<String, bool> _availablePages = {
    'tven_ventas/VentasView': true, // This redirects to ItemsViewStock
    // Add all your available pages here
    // Format: 'page_route': true,
  };
  
  @override
  void initState() {
    super.initState();
    
    // Filter menu items without valid routes
    _filteredMenuItems = _filterValidMenuItems(widget.menuItems);
    
    // Initialize main controller
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    
    // Auto-expand root items (level 1)
    _autoExpandRootItems();
    
    // Auto-expand items containing the selected item
    _autoExpandParents();
  }
  
  // Method to filter menu items without valid routes or existing pages
  List<Vista> _filterValidMenuItems(List<Vista> items) {
    // List to store filtered items
    List<Vista> validItems = [];
    
    for (var item in items) {
      if (item.items != null && item.items!.isNotEmpty) {
        // Filter children first
        List<Vista> validChildren = _filterValidMenuItems(item.items!);
        
        // Include this item only if it has valid children or a valid route with existing page
        if (validChildren.isNotEmpty || _hasValidRouteAndPage(item)) {
          // Create a copy of the item with filtered children
          Vista newItem = Vista(
            codVista: item.codVista,
            codVistaPadre: item.codVistaPadre,
            titulo: item.titulo,
            descripcion: item.descripcion,
            imagen: item.imagen,
            autorizar: item.autorizar,
            audUsuarioI: item.audUsuarioI,
            fila: item.fila,
            tieneHijo: item.tieneHijo,
            routerLink: item.routerLink,
            label: item.label,
            icon: item.icon,
            direccion: item.direccion,
            esRaiz: item.esRaiz,
            // Assign filtered children
            items: validChildren,
          );
          validItems.add(newItem);
        }
      } else if (_hasValidRouteAndPage(item)) {
        // This is a leaf item with a valid route and existing page
        validItems.add(item);
      }
    }
    
    return validItems;
  }
  
  // Check if an item has a valid route and corresponding page
  bool _hasValidRouteAndPage(Vista item) {
    // First check if the route is valid
    if (item.direccion == null || item.direccion!.isEmpty) {
      return false;
    }
    
    // Then check if the page exists in our available pages map
    return _pageExists(item.direccion!);
  }
  
  // Check if a page exists in the project
  bool _pageExists(String route) {
    // Check in our map of available pages
    return _availablePages.containsKey(route);
  }
  
  // Handle navigation with special redirection
  void _handleNavigation(BuildContext context, Vista item) {
    // Check if it's the special route
    if (item.direccion == 'tven_ventas/VentasView') {
      // Redirect to ItemsViewStock
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ItemsViewStock(),
        ),
      );
    } else {
      // Normal navigation
      widget.onItemSelected(item);
    }
  }
  
  @override
  void dispose() {
    _expandController.dispose();
    for (var controller in _itemAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Get or create animation controller for a specific item
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
      // Expand only top-level elements
      if (item.esRaiz == 1) {
        // Use null-safe access with nullish coalescing operator
        _expandedItems[item.codVista ?? 0] = true;
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
      // Find and expand parents of the selected item
      _expandParentOf(widget.menuItems, widget.selectedItemId!);
    }
  }
  
  // Recursive function to find and expand parents of the selected item
  bool _expandParentOf(List<Vista> items, int targetId) {
    for (var item in items) {
      if (item.codVista == targetId) {
        return true;
      }
      
      if (item.items != null && item.items!.isNotEmpty) {
        bool foundInChildren = _expandParentOf(item.items!, targetId);
        if (foundInChildren) {
          // If target found in children, expand this item
          // Use null-safe access
          _expandedItems[item.codVista ?? 0] = true;
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
    
    // If there are no valid items after filtering, return an empty container
    if (_filteredMenuItems.isEmpty) {
      return Container();
    }
    
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
          // Use filtered list instead of widget.menuItems
          itemCount: _filteredMenuItems.length,
          itemBuilder: (context, index) {
            final item = _filteredMenuItems[index];
            
            // Create entrance animation for each menu item
            // Use null-safe access
            final itemController = _getItemController(item.codVista ?? 0);
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
    // Use null-safe access with nullish coalescing operator
    bool isExpanded = _expandedItems[item.codVista ?? 0] ?? false;
    bool isSelected = widget.selectedItemId == item.codVista;
    bool isHovered = _hoveredItemId == item.codVista;
    
    // Determine colors based on theme
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Create dynamic color palette
    final selectedBgColor = colorScheme.primaryContainer.withOpacity(0.15);
    final hoveredBgColor = colorScheme.primaryContainer.withOpacity(0.08);
    final primaryColor = colorScheme.primary;
    
    // Gradient effects (optional)
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
    
    // Determine which icon to use based on the item structure
    IconData iconData = level == 0
        ? _getCategoryIcon(item.label ?? "")
        : hasChildren
            ? Icons.folder
            : item.icon != null && item.icon!.isNotEmpty
                ? _getIconForString(item.icon!)
                : Icons.description_outlined;
    
    // Determine icon and text colors
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
    
    // Apply indentation based on level
    double leftPadding = 16.0 * level;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category header for level 0 elements
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
                    (item.label ?? "").toUpperCase(),
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
        
        // Menu item with enhanced effects
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
                      // Use null-safe access
                      _expandedItems[item.codVista ?? 0] = !isExpanded;
                    });
                  } else {
                    // Log to console which route/link is being clicked
                    print('===== MENU ITEM CLICKED =====');
                    print('Title: ${item.label}');
                    print('ID: ${item.codVista}');
                    print('Route/Link: ${item.direccion ?? "No route defined"}');
                    print('============================');
                    
                    // Use the new navigation method
                    _handleNavigation(context, item);
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
                      
                      // Decorative icon container
                      if (level > 0)
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryColor.withOpacity(0.1)
                                : isHovered
                                    ? primaryColor.withOpacity(0.05)
                                    : colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                      
                      // Item title with subtle animation
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
                          child: Text(item.label ?? ""),
                        ),
                      ),
                      
                      // Counter or badge (example)
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
                      
                      // Indicator for expandable items
                      if (hasChildren)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCirc,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isHovered || isSelected 
                                ? primaryColor.withOpacity(0.1) 
                                : colorScheme.surfaceContainerHighest.withOpacity(0.3),
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
                      // Indicator for navigable items
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
        
        // Child elements with improved animation
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
                        
                        // Animate child items entry
                        final delay = index * 50;
                        
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
          
        // Animated separator
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
  
  // Method to determine if showing a badge on an item
  bool _shouldShowBadge(Vista item) {
    // Example - implement your actual logic here
    return false;
  }
  
  // Method to get badge count
  String _getBadgeCount(Vista item) {
    // Example - implement your actual logic
    return "3";
  }
  
  // Function to assign icons based on category name
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
  
  // Function to map icon strings to IconData
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