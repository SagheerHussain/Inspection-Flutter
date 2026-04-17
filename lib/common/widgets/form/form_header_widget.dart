import 'package:flutter/material.dart';
import '../../../utils/constants/sizes.dart';

class FormHeaderWidget extends StatelessWidget {
  const FormHeaderWidget({
    super.key,
    this.imageColor,
    this.heightBetween,
    required this.image,
    required this.title,
    required this.subTitle,
    this.imageHeight = 0.15,
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.imageAlignment = Alignment.centerLeft,
  });

  //Variables -- Declared in Constructor
  final Color? imageColor;
  final double imageHeight;
  final double? heightBetween;
  final String image, title, subTitle;
  final CrossAxisAlignment crossAxisAlignment;
  final TextAlign? textAlign;
  final AlignmentGeometry imageAlignment;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Align(
            alignment: imageAlignment,
            child: Image(
              image: AssetImage(image), 
              color: imageColor, 
              height: size.height * imageHeight
            ),
          ),
          const SizedBox(height: TSizes.sm),
          Text(title, style: Theme.of(context).textTheme.displayLarge, textAlign: textAlign),
          const SizedBox(height: TSizes.xs),
          Text(subTitle, textAlign: textAlign, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
