import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:novadis_cri/core/theme/app_theme.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:novadis_cri/data/models/site_model.dart';
import 'package:novadis_cri/data/repositories/cri_remote_repository.dart';

/// Callback invoqué quand un site est sélectionné depuis la base de données.
/// Fournit les données du site pour auto-complétion des champs.
typedef OnSiteSelected = void Function(SiteModel site);

/// Callback invoqué quand le texte du champ site change manuellement.
typedef OnSiteTextChanged = void Function(String value);

/// Widget de sélection de site avec recherche intelligente et auto-complétion.
/// Recherche insensible à la casse et aux accents par nom, adresse, ville ou code postal.
class SiteSelector extends StatefulWidget {
  final String initialValue;
  final CriRemoteRepository repository;
  final OnSiteSelected onSiteSelected;
  final OnSiteTextChanged onSiteTextChanged;

  const SiteSelector({
    super.key,
    required this.initialValue,
    required this.repository,
    required this.onSiteSelected,
    required this.onSiteTextChanged,
  });

  @override
  State<SiteSelector> createState() => _SiteSelectorState();
}

class _SiteSelectorState extends State<SiteSelector> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Site *', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        FormBuilderField<String>(
          name: 'site',
          initialValue: widget.initialValue,
          validator: FormBuilderValidators.required(errorText: 'Site requis'),
          builder: (FormFieldState<String> field) {
            return Autocomplete<SiteModel>(
              initialValue: TextEditingValue(text: field.value ?? ''),
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.length < 2) {
                  return const Iterable<SiteModel>.empty();
                }
                final results = await widget.repository
                    .searchSitesFromDatabase(textEditingValue.text);
                if (results.isEmpty) {
                  return const Iterable<SiteModel>.empty();
                }
                return results;
              },
              displayStringForOption: (SiteModel site) => site.nomDuSite,
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                      boxShadow: AppTheme.shadowMd,
                    ),
                    child: Material(
                      elevation: 0,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      color: Colors.transparent,
                      child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: 300,
                        maxWidth: 500,
                      ),
                      child: options.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                'Aucun site trouvé',
                                style: TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.textTertiary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final site = options.elementAt(index);
                                return ListTile(
                                  leading: Icon(
                                    Icons.location_on,
                                    size: 20,
                                    color: AppTheme.primaryContent,
                                  ),
                                  title: Text(
                                    site.nomDuSite,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    [
                                      if (site.ville != null &&
                                          site.ville!.isNotEmpty)
                                        site.ville,
                                      if (site.codePostal != null &&
                                          site.codePostal!.isNotEmpty)
                                        site.codePostal,
                                    ].join(' '),
                                    style: TextStyle(
                                      color: AppTheme.textTertiary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  dense: true,
                                  onTap: () => onSelected(site),
                                );
                              },
                            ),
                    ),
                  ),
                  ),
                );
              },
              onSelected: (SiteModel selection) {
                field.didChange(selection.nomDuSite);
                widget.onSiteSelected(selection);
              },
              fieldViewBuilder: (
                context,
                textEditingController,
                focusNode,
                onFieldSubmitted,
              ) {
                if (textEditingController.text != field.value &&
                    field.value != null &&
                    !focusNode.hasFocus) {
                  textEditingController.text = field.value!;
                }
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    hintText: 'Rechercher un site...',
                    prefixIcon: const Icon(Icons.location_on),
                    errorText: field.errorText,
                    helperText: 'Recherche par nom, adresse, ville ou code postal',
                    helperStyle: TextStyle(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onChanged: (val) {
                    field.didChange(val);
                    widget.onSiteTextChanged(val);
                  },
                  onSubmitted: (_) => onFieldSubmitted(),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
