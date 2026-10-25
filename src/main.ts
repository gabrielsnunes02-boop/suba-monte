import "./style.css";
import { App } from "./ui/app";

new App(document.getElementById("app")!);

// Service worker só em produção: permite jogar offline depois do primeiro acesso.
if (import.meta.env.PROD && "serviceWorker" in navigator) {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js").catch(() => {});
  });
}
