import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../app/controllers/home_controller.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sehatly')),
      body: Center(
        child: Obx(() => Text(
              '${controller.count}',
              style: Theme.of(context).textTheme.headlineMedium,
            )),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.increment,
        child: const Icon(Icons.add),
      ),
    );
  }
}
