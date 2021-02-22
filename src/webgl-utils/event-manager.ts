export class EventManager<T extends { [K: string]: {} } = EventManager.DefaultEvents> {
    private events: {
        [K in keyof T]?: Set<EventManager.EventFn<T, K>>
    } = {};

    on<K extends keyof T>(event: K, fn: EventManager.EventFn<T, K>) {
        const eventSet = (this.events[event] ?? new Set()) as Set<EventManager.EventFn<T, K>>
        eventSet.add(fn);
        this.events[event] = eventSet;
    }

    off<K extends keyof T>(event: K, fn: EventManager.EventFn<T, K>) {
        const eventSet = (this.events[event] ?? new Set()) as Set<EventManager.EventFn<T, K>>
        eventSet.delete(fn);
    }

    fire<K extends keyof T>(event: K, arg: T[K]) {
        const eventSet = (this.events[event] ?? new Set()) as Set<EventManager.EventFn<T, K>>
        for (let handler of eventSet) {
            handler(arg);
        }
    }
}

export namespace EventManager {
    export type DefaultEvents = {
        "mousemove": MouseEvent,
        "click": MouseEvent,
    }

    export type EventFn<T extends { [K: string]: {} }, U extends keyof T> = (arg: T[U]) => void
}