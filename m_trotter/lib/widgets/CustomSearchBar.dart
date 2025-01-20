import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool initialFocus;
  final bool isLayerVisible;
  final Function(bool) onLayerToggle;
  final VoidCallback onClear;
  final Function(String) onTextChanged;

  const CustomSearchBar({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.initialFocus,
    required this.isLayerVisible,
    required this.onLayerToggle,
    required this.onClear,
    required this.onTextChanged,
  }) : super(key: key);

  @override
  CustomSearchBarState createState() => CustomSearchBarState();

  // Méthode statique pour changer le focus
  static void toggleFocus(GlobalKey<CustomSearchBarState> key, bool focus) {
    final state = key.currentState;
    if (state != null) {
      if (focus) {
        state.widget.focusNode.requestFocus();
      } else {
        state.widget.focusNode.unfocus();
      }
    }
  }
}

class CustomSearchBarState extends State<CustomSearchBar> {
  @override
  void initState() {
    super.initState();
    if (widget.initialFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.focusNode.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 30.0, left: 8.0, right: 8.0),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        decoration: InputDecoration(
          hintText: 'Où voulez-vous aller ?',
          prefixIcon: GestureDetector(
            onTap: () {
              if (widget.isLayerVisible) {
                widget.onClear(); // Appeler la fonction de réinitialisation
                widget.focusNode.unfocus();
              } else {
                widget.focusNode.requestFocus(); // Demander le focus si non visible
              }
            },
            child: Icon(
              widget.isLayerVisible ? Icons.arrow_back : Icons.search,
            ),
          ),
          suffixIcon: widget.isLayerVisible
              ? GestureDetector(
                  onTap: () {
                    widget.onClear(); // Réinitialiser en appuyant sur la croix
                  },
                  child: const Icon(Icons.clear),
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
        ),
        onChanged: widget.onTextChanged,
        onTap: () {
          widget.onLayerToggle(true); // Afficher le layer quand tapé
        },
      ),
    );
  }
}