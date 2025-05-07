## 🧱 Module Summary - lib/ 구조

lib/
├── app.dart
├── core
│   ├── config
│   │   ├── app_config.dart
│   │   └── env_config.dart
│   ├── di
│   │   ├── bindings
│   │   │   ├── controller_binding.dart
│   │   │   ├── data_source_binding.dart
│   │   │   ├── processor_binding.dart
│   │   │   ├── repository_binding.dart
│   │   │   ├── service_binding.dart
│   │   │   ├── usecase_binding.dart
│   │   │   └── view_bindings.dart
│   │   └── injection_container.dart
│   ├── error
│   │   ├── exception.dart
│   │   └── failure.dart
│   ├── lifecycle
│   │   └── app_lifecycle_manager.dart
│   ├── logger
│   │   └── app_logger.dart
│   ├── memory
│   │   └── object_pool.dart
│   ├── navigation
│   │   └── app_router.dart
│   ├── network
│   │   ├── api_client.dart
│   │   └── connectivity_manager.dart
│   ├── pipeline
│   │   └── trade_pipeline.dart
│   ├── sample.dart
│   ├── scaling
│   │   └── rate_limiter.dart
│   ├── services
│   │   └── platform_service.dart
│   ├── storage
│   │   └── local_storage.dart
│   ├── streaming
│   │   └── backpressure_controller.dart
│   ├── theme
│   │   ├── app_theme_manager.dart
│   │   └── app_theme.dart
│   └── workers
│       └── isolate_worker.dart
├── data
│   ├── datasources
│   │   ├── market_data_source.dart
│   │   ├── mock_market_data_source.dart
│   │   ├── real_market_data_source.dart
│   │   ├── socket_trade_source.dart
│   │   └── trade_data_source.dart
│   ├── models
│   │   ├── market_model.dart
│   │   └── trade_model.dart
│   ├── processors
│   │   └── trade_processor.dart
│   └── repositories
│       └── trade_repository_impl.dart
├── domain
│   ├── entities
│   │   └── trade.dart
│   ├── events
│   │   └── trade_event.dart
│   ├── repositories
│   │   └── trade_repository.dart
│   └── usecases
│       ├── get_filtered_trades.dart
│       ├── get_momentary_trades.dart
│       ├── get_surge_trades.dart
│       └── get_volume_data.dart
├── main.dart
├── presentation
│   ├── app.dart
│   ├── common
│   │   ├── empty_state_widget.dart
│   │   ├── error_widget.dart
│   │   └── loading_widget.dart
│   ├── controllers
│   │   ├── main_controller.dart
│   │   ├── momentary_controller.dart
│   │   ├── surge_controller.dart
│   │   ├── trade_controller.dart
│   │   └── volume_controller.dart
│   ├── pages
│   │   ├── main
│   │   │   └── main_view.dart
│   │   ├── momentary
│   │   │   └── momentary_view.dart
│   │   ├── notifications
│   │   │   └── notifications_view.dart
│   │   ├── settings
│   │   │   └── settings_view.dart
│   │   ├── splash
│   │   │   └── splash_view.dart
│   │   ├── surge
│   │   │   └── surge_view.dart
│   │   ├── trade
│   │   │   └── trade_view.dart
│   │   └── volume
│   │       └── volume_view.dart
│   └── widgets
│       ├── common
│       │   └── connection_status_bar.dart
│       ├── common_app_bar.dart
│       ├── drawer
│       │   └── app_drawer.dart
│       ├── index.dart
│       └── trade_card_widget.dart
└── utils

44 directories, 67 files
