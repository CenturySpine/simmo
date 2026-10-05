import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/native_share.dart';
import '../../legal/ui/site_footer.dart';
import '../../../shared/simmo_logo.dart';
import '../data/saved_projects.dart';
import '../data/share_link.dart';
import '../domain/project.dart';
import '../domain/simulation_input.dart';
import '../domain/simulator.dart';
import 'advanced_params.dart';
import 'project_view.dart';

/// The whole app: the buyer's situation, one tab per project, the shown
/// project below.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.saved, this.sharedFragment = ''});

  /// Projects kept on the device; null in tests.
  final SavedProjects? saved;

  /// Fragment of the opening URL: a shared simulation, if any.
  final String sharedFragment;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// Never empty: a new buyer starts with one project.
  late List<Project> _projects;
  var _active = 0;

  /// One per project: its widgets start afresh when another project takes
  /// its place.
  late List<Key> _keys;

  /// No project kept yet: the buyer's situation is to fill in.
  late final bool _firstVisit;

  /// The simulation of the opening link: a tab of its own, never kept.
  Project? _shared;
  var _showShared = false;

  @override
  void initState() {
    super.initState();
    final saved = widget.saved;
    _projects = saved?.projects ?? const [];
    _firstVisit = _projects.isEmpty;
    if (_firstVisit) _projects = const [Project(SimulationInput())];
    _active = (saved?.active ?? 0).clamp(0, _projects.length - 1);
    _keys = [for (final _ in _projects) UniqueKey()];
    final shared = decodeInput(widget.sharedFragment);
    if (shared != null) {
      _shared = Project.received(shared);
      _showShared = true;
    }
  }

  Project get _shown => _showShared ? _shared! : _projects[_active];

  void _save() => widget.saved?.save(_projects, _active);

  void _update(Project project) {
    if (_showShared) {
      setState(() => _shared = project);
      return;
    }
    setState(() {
      // The buyer is the same in every project.
      _projects = [
        for (final (i, p) in _projects.indexed)
          i == _active
              ? project
              : Project(p.input.withBuyerOf(project.input), p.typed),
      ];
    });
    _save();
  }

  void _select(int index) {
    setState(() {
      _showShared = false;
      _active = index;
    });
    _save();
  }

  /// A project for another property: same buyer, and the rate of the project
  /// shown.
  Project get _newProject => Project(
    const SimulationInput()
        .withBuyerOf(_projects.first.input)
        .copyWith(rate: _projects[_active].input.rate),
  );

  void _add() {
    setState(() {
      _projects = [..._projects, _newProject];
      _keys.add(UniqueKey());
      _active = _projects.length - 1;
      _showShared = false;
    });
    _save();
  }

  Future<void> _delete() async {
    final name = _projects[_active].name(_active + 1);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce projet ?'),
        content: Text('« $name » sera effacé de cet appareil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      final replacement = _newProject;
      _projects = [..._projects]..removeAt(_active);
      _keys.removeAt(_active);
      // The last project gives way to a new one.
      if (_projects.isEmpty) {
        _projects = [replacement];
        _keys.add(UniqueKey());
      }
      _active = min(_active, _projects.length - 1);
    });
    _save();
  }

  /// Forgets every project kept on this device (RGPD) and starts afresh.
  void _clearData() {
    widget.saved?.clear();
    setState(() {
      _projects = const [Project(SimulationInput())];
      _keys = [UniqueKey()];
      _active = 0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Données de cet appareil effacées')),
    );
  }

  /// Shares a link reproducing the shown simulation: the share sheet on a
  /// phone, otherwise a copy; the link is shown when the browser refuses
  /// the clipboard.
  Future<void> _share() async {
    final link = shareLink(_shown.input);
    if (await shareNatively(title: 'Simulation Simmo', url: link)) return;
    try {
      await Clipboard.setData(ClipboardData(text: link));
    } on PlatformException {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lien de la simulation'),
          content: SelectableText(link),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien de la simulation copié')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 960;
            return SingleChildScrollView(
              padding: EdgeInsets.all(wide ? 32 : 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(onShare: _share),
                      const SizedBox(height: 24),
                      BuyerParams(
                        input: _shown.input,
                        result: simulate(_shown.input),
                        onChanged: (input) =>
                            _update(Project(input, _shown.typed)),
                        wide: wide,
                        initiallyExpanded: _firstVisit,
                        shared: _showShared,
                      ),
                      const SizedBox(height: 24),
                      _tabs(),
                      const SizedBox(height: 16),
                      ProjectView(
                        key: _showShared
                            ? const ValueKey('shared')
                            : _keys[_active],
                        project: _shown,
                        onChanged: _update,
                        wide: wide,
                      ),
                      SiteFooter(onClearData: _clearData),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The shared simulation first, then the projects; the shown tab can be
  /// closed.
  Widget _tabs() {
    Widget tab(
      String name, {
      required bool shown,
      required VoidCallback onSelect,
      required VoidCallback onClose,
      required String closeTooltip,
    }) => InputChip(
      label: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      selected: shown,
      onSelected: (_) => onSelect(),
      onDeleted: shown ? onClose : null,
      deleteButtonTooltipMessage: closeTooltip,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_shared != null)
          tab(
            'Lien partagé',
            shown: _showShared,
            onSelect: () => setState(() => _showShared = true),
            onClose: () => setState(() {
              _shared = null;
              _showShared = false;
            }),
            closeTooltip: 'Fermer',
          ),
        for (final (i, project) in _projects.indexed)
          tab(
            project.name(i + 1),
            shown: !_showShared && i == _active,
            onSelect: () => _select(i),
            onClose: _delete,
            closeTooltip: 'Supprimer le projet',
          ),
        ActionChip(
          avatar: const Icon(Icons.add),
          label: const Text('Nouveau projet'),
          onPressed: _add,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onShare});

  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        const SimmoLogo(size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Simmo',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              Text(
                'Simulation de prêt immobilier, avec un petit truc en plus',
                style: text.bodySmall,
              ),
            ],
          ),
        ),
        TextButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.link, size: 20),
          label: const Text('Partager'),
        ),
      ],
    );
  }
}
