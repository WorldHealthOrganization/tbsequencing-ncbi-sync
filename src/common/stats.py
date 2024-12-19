class Stats:
    store: dict[str, int]

    def __init__(self) -> None:
        self.store = dict()

    def increment(self, key, by=1):
        self.store[key] = self.store.get(key, 0) + by

    def merge(self, b: "Stats"):
        for k, v in b.store.items():
            self.increment(k, by=v)

    def __repr__(self):
        return "Stats:" + " ".join(f"{k}={v}" for k, v in self.store.items())

    def __str__(self):
        return "Stats:" + " ".join(f"{k}={v}" for k, v in self.store.items())
