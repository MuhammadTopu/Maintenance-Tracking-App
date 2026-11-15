import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/guided_answer_model.dart';
import '../../../../data/models/guided_question_model.dart';

/// One Home / Other question. The answer widget is chosen from the question's
/// `input_type`:
///
///  * single choice → radio-style rows
///  * multiple choice → checkbox-style rows
///  * yes / no → Yes / No / Not sure buttons
///  * numeric → number field
///  * text → text field (also used when a choice question has no options)
///
/// The tile does not keep the answer. It shows [value] (the draft described in
/// [GuidedAnswerBuilder]) and reports every change through [onChanged], so the
/// parent always knows what would be submitted.
class GuidedQuestionTile extends StatefulWidget {
  const GuidedQuestionTile({
    super.key,
    required this.index,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final GuidedQuestion question;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  State<GuidedQuestionTile> createState() => _GuidedQuestionTileState();
}

class _GuidedQuestionTileState extends State<GuidedQuestionTile> {
  late final TextEditingController _controller;

  GuidedQuestion get _q => widget.question;

  bool get _isNotSure => widget.value == GuidedAnswerBuilder.notSure;

  @override
  void initState() {
    super.initState();
    final initial = widget.value;
    _controller = TextEditingController(
      text: initial is String && initial != GuidedAnswerBuilder.notSure
          ? initial
          : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setNotSure() {
    _controller.clear(); // does not trigger the field's onChanged
    widget.onChanged(GuidedAnswerBuilder.notSure);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xffF0F0F1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (_q.reason.isNotEmpty) ...[
            SizedBox(height: 8.h),
            _buildReason(),
          ],
          SizedBox(height: 14.h),
          _buildAnswerArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22.w,
          height: 22.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            '${widget.index}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            _q.text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
        if (_q.optional) ...[
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: const Color(0xffF1F1F2),
              borderRadius: BorderRadius.circular(99.r),
            ),
            child: Text(
              'Optional',
              style: TextStyle(
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReason() {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F8),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 14.sp,
            color: Colors.grey[500],
          ),
          SizedBox(width: 6.w),
          Expanded(
            child: Text(
              _q.reason,
              style: TextStyle(
                fontSize: 11.5.sp,
                color: Colors.grey[600],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerArea() {
    switch (_q.effectiveType) {
      case QuestionInputType.singleChoice:
        return _buildSingleChoice();
      case QuestionInputType.multiChoice:
        return _buildMultiChoice();
      case QuestionInputType.yesNo:
        return _buildYesNo();
      case QuestionInputType.numeric:
        return _buildField(numeric: true);
      case QuestionInputType.text:
        return _buildField(numeric: false);
    }
  }

  // ---------------- choices ----------------

  Widget _buildSingleChoice() {
    final selected = widget.value;
    return Column(
      children: [
        for (final option in _q.choices)
          _OptionRow(
            label: option,
            selected: selected == option,
            multi: false,
            onTap: () {
              // An optional question can be cleared by tapping the choice
              // again, which means "skip".
              if (selected == option && _q.optional) {
                widget.onChanged(null);
              } else {
                widget.onChanged(option);
              }
            },
          ),
      ],
    );
  }

  Widget _buildMultiChoice() {
    final selected = <String>{
      if (widget.value is Iterable)
        for (final item in widget.value as Iterable) item.toString(),
    };

    void toggle(String option) {
      final next = {...selected};
      if (!next.remove(option)) {
        next.add(option);
        // "Not sure" cannot be combined with a real choice.
        if (option == GuidedAnswerBuilder.notSure) {
          next
            ..clear()
            ..add(option);
        } else {
          next.remove(GuidedAnswerBuilder.notSure);
        }
      }
      // Keep the order the options were listed in.
      widget.onChanged([
        for (final choice in _q.choices)
          if (next.contains(choice)) choice,
      ]);
    }

    return Column(
      children: [
        for (final option in _q.choices)
          _OptionRow(
            label: option,
            selected: selected.contains(option),
            multi: true,
            onTap: () => toggle(option),
          ),
      ],
    );
  }

  Widget _buildYesNo() {
    final selected = widget.value;
    return Row(
      children: [
        for (var i = 0; i < _q.choices.length; i++) ...[
          if (i > 0) SizedBox(width: 8.w),
          Expanded(
            child: _OptionPill(
              label: _q.choices[i],
              selected: selected == _q.choices[i],
              onTap: () {
                if (selected == _q.choices[i] && _q.optional) {
                  widget.onChanged(null);
                } else {
                  widget.onChanged(_q.choices[i]);
                }
              },
            ),
          ),
        ],
      ],
    );
  }

  // ---------------- typed input ----------------

  Widget _buildField({required bool numeric}) {
    final draft = widget.value;
    final typed = draft is String && !_isNotSure ? draft : '';

    // Show "enter a valid number" only once something was typed.
    String? errorText;
    if (numeric && typed.trim().isNotEmpty) {
      errorText = GuidedAnswerBuilder.build(_q, typed).error;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          textCapitalization:
          numeric ? TextCapitalization.none : TextCapitalization.sentences,
          inputFormatters: numeric
              ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
              : null,
          maxLines: numeric ? 1 : 3,
          minLines: 1,
          onChanged: (text) => widget.onChanged(text),
          style: TextStyle(fontSize: 14.sp),
          decoration: InputDecoration(
            hintText: numeric ? 'Enter a number' : 'Type your answer',
            hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
            errorText: errorText,
            filled: true,
            fillColor: const Color(0xffFAFAFA),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
            enabledBorder: _border(const Color(0xffE0E0E0)),
            focusedBorder: _border(AppColors.primaryColor),
            errorBorder: _border(const Color(0xffC62828)),
            focusedErrorBorder: _border(const Color(0xffC62828)),
          ),
        ),
        SizedBox(height: 8.h),
        // "Not sure" is accepted for every question type. Choice questions list
        // it among their options; free input gets this button.
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 110.w,
            child: _OptionPill(
              label: GuidedAnswerBuilder.notSure,
              selected: _isNotSure,
              onTap: () {
                if (_isNotSure) {
                  widget.onChanged(null);
                } else {
                  _setNotSure();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10.r),
    borderSide: BorderSide(color: color),
  );
}

/// A full-width, selectable row. Radio-style for single choice, checkbox-style
/// for multiple choice.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.selected,
    required this.multi,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool multi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primaryColor;
    final IconData icon = multi
        ? (selected ? Icons.check_box_rounded : Icons.check_box_outline_blank)
        : (selected
        ? Icons.radio_button_checked_rounded
        : Icons.radio_button_unchecked_rounded);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : Colors.white,
            border: Border.all(
              color: selected ? color : const Color(0xffE0E0E0),
              width: selected ? 1.4 : 1,
            ),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 18.sp,
                color: selected ? color : Colors.grey[400],
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? color : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact selectable button, used for Yes / No / Not sure.
class _OptionPill extends StatelessWidget {
  const _OptionPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.primaryColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          border: Border.all(
            color: selected ? color : const Color(0xffE0E0E0),
            width: selected ? 1.4 : 1,
          ),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? color : Colors.grey[700],
          ),
        ),
      ),
    );
  }
}