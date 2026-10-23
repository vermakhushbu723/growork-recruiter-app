import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import '../../data/talent_model.dart';

Color talentKindColor(TalentKind kind) =>
    kind == TalentKind.candidate ? AppColors.tintBlue : AppColors.tintGreen;

class TalentCard extends ConsumerWidget {
  const TalentCard({super.key, required this.talent, required this.onTap});

  final TalentModel talent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = talent;
    final saved = ref.watch(savedTalentProvider).contains(t.id);
    final sub = GoogleFonts.inter(fontSize: 8.5, color: context.textSubColor);
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(11, 9, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(name: t.name, size: 42),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: t.available
                            ? AppColors.tintGreen
                            : const Color(0xFF9AA3B2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.surfaceColor,
                          width: 1.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            t.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              height: 1.25,
                              fontWeight: FontWeight.w800,
                              color: headingColor(context),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TintTag(
                          t.kind.label,
                          color: talentKindColor(t.kind),
                          height: 15,
                        ),
                      ],
                    ),
                    Text(
                      t.headline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        height: 1.3,
                        color: context.textSubColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 11,
                          color: AppColors.brandAmber,
                        ),
                        const SizedBox(width: 2),
                        Text('${t.rating}', style: sub),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.location_on_outlined,
                          size: 10,
                          color: context.textSubColor,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            t.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: sub,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(t.experience, style: sub),
                      ],
                    ),
                  ],
                ),
              ),
              InkResponse(
                onTap: () => context.runApi(
                  () => ref.read(savedTalentProvider.notifier).toggle(t.id),
                  success: saved ? 'Removed from saved' : '${t.name} saved',
                ),
                radius: 16,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    saved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 16,
                    color: saved ? context.accentColor : headingColor(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final s in t.skills.take(4)) SkillChip(s),
              if (t.skills.length > 4) SkillChip('+${t.skills.length - 4}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                t.rate,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: context.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              if (t.jobsDone > 0)
                Text('${t.jobsDone} jobs done', style: sub)
              else
                Text(t.available ? 'Open to work' : 'Not looking', style: sub),
              const Spacer(),
              ArrowButton(label: 'View Profile', onTap: onTap, height: 25),
            ],
          ),
        ],
      ),
    );
  }
}
