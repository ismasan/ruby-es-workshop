## Reactive, event-sourced demo app

Libraries used: 

* [Sourced](https://github.com/ismasan/sourced) (`ccc` branch) for async Event Sourcing.
* [Sidereal](https://github.com/ismasan/sidereal) for reactive, multi-player web apps.
* [Sourced::UI](https://github.com/ismasan/sourced-ui) (`ccc` branch) for Sourced system dashboard at /sourced

```
bundle exec rake db:migrate
```

Run with Falcon

```
bundle exec falcon host
```

Visit [http://localhost:9292](http://localhost:9292)
