/**
 * 实验语音录制工具 — MediaRecorder + 可选 Web Speech API 转写
 * 用法: VoiceRecorderKit.attach({ textarea, key, meta })
 */
window.VoiceRecorderKit = (function() {
    const store = {};   // key -> { blob, durationMs, mimeType, meta, transcript }
    let mediaRecorder = null;
    let mediaStream = null;
    let activeKey = null;
    let chunks = [];
    let startTime = 0;
    let recognition = null;
    let activeUI = null;

    function isSupported() {
        return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia && window.MediaRecorder);
    }

    function speechSupported() {
        return !!(window.SpeechRecognition || window.webkitSpeechRecognition);
    }

    function formatDuration(ms) {
        const s = Math.floor(ms / 1000);
        return String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(s % 60).padStart(2, '0');
    }

    function stopActive() {
        if (mediaRecorder && mediaRecorder.state !== 'inactive') {
            try { mediaRecorder.stop(); } catch (e) { /* ignore */ }
        }
        if (recognition) {
            try { recognition.stop(); } catch (e) { /* ignore */ }
        }
        if (mediaStream) {
            mediaStream.getTracks().forEach(t => t.stop());
            mediaStream = null;
        }
        if (activeUI) {
            activeUI.classList.remove('vr-recording');
            const btn = activeUI.querySelector('.vr-btn-record');
            if (btn) { btn.textContent = '🎙️ 开始录音'; btn.classList.remove('vr-recording'); }
        }
        activeKey = null;
        activeUI = null;
    }

    function startSpeechToText(textarea, key) {
        if (!speechSupported()) return;
        const SR = window.SpeechRecognition || window.webkitSpeechRecognition;
        recognition = new SR();
        recognition.lang = 'zh-CN';
        recognition.continuous = true;
        recognition.interimResults = true;
        let baseText = textarea.value;
        recognition.onresult = function(event) {
            let interim = '';
            let final = '';
            for (let i = event.resultIndex; i < event.results.length; i++) {
                const t = event.results[i][0].transcript;
                if (event.results[i].isFinal) final += t;
                else interim += t;
            }
            if (final) {
                baseText += final;
                if (store[key]) store[key].transcript = baseText;
            }
            textarea.value = baseText + interim;
        };
        recognition.onerror = function() { /* 转写失败不影响录音 */ };
        try { recognition.start(); } catch (e) { /* ignore */ }
    }

    function attach(options) {
        if (!isSupported()) {
            console.warn('VoiceRecorderKit: 当前浏览器不支持录音');
            return null;
        }

        const textarea = options.textarea;
        const key = options.key;
        const meta = options.meta || {};
        const accent = options.accentColor || '#5c9fd4';

        stopActive();

        const panel = document.createElement('div');
        panel.className = 'vr-panel';
        panel.innerHTML = `
            <div class="vr-header">
                <span class="vr-title">🎤 语音作答（可选）</span>
                <span class="vr-status" data-status>未录音</span>
            </div>
            <div class="vr-hint">可打字、可录音，或边录边自动转写为文字。需允许浏览器使用麦克风。</div>
            <div class="vr-controls">
                <button type="button" class="vr-btn vr-btn-record">🎙️ 开始录音</button>
                <button type="button" class="vr-btn vr-btn-stop" disabled>⏹ 停止</button>
                <button type="button" class="vr-btn vr-btn-play" disabled>▶ 播放</button>
                <button type="button" class="vr-btn vr-btn-clear" disabled>🗑 删除录音</button>
            </div>
            <div class="vr-wave" style="display:none;"><span></span><span></span><span></span><span></span><span></span></div>
        `;

        textarea.parentNode.insertBefore(panel, textarea.nextSibling);

        const statusEl = panel.querySelector('[data-status]');
        const btnRecord = panel.querySelector('.vr-btn-record');
        const btnStop = panel.querySelector('.vr-btn-stop');
        const btnPlay = panel.querySelector('.vr-btn-play');
        const btnClear = panel.querySelector('.vr-btn-clear');
        const wave = panel.querySelector('.vr-wave');

        panel.style.setProperty('--vr-accent', accent);

        function updateStatus() {
            const rec = store[key];
            if (rec && rec.blob) {
                statusEl.textContent = '已录音 ' + formatDuration(rec.durationMs);
                statusEl.className = 'vr-status vr-done';
                btnPlay.disabled = false;
                btnClear.disabled = false;
            } else {
                statusEl.textContent = '未录音';
                statusEl.className = 'vr-status';
                btnPlay.disabled = true;
                btnClear.disabled = true;
            }
        }

        if (store[key]) updateStatus();

        btnRecord.onclick = async function() {
            if (mediaRecorder && mediaRecorder.state === 'recording') return;
            try {
                mediaStream = await navigator.mediaDevices.getUserMedia({ audio: true });
                const mimeType = MediaRecorder.isTypeSupported('audio/webm;codecs=opus')
                    ? 'audio/webm;codecs=opus' : 'audio/webm';
                chunks = [];
                mediaRecorder = new MediaRecorder(mediaStream, { mimeType });
                startTime = Date.now();
                activeKey = key;
                activeUI = panel;

                mediaRecorder.ondataavailable = e => { if (e.data.size > 0) chunks.push(e.data); };
                mediaRecorder.onstop = function() {
                    const durationMs = Date.now() - startTime;
                    const blob = new Blob(chunks, { type: mimeType });
                    store[key] = {
                        blob, durationMs, mimeType, meta,
                        transcript: textarea.value || '',
                        filename: (meta.filename || key) + '.webm'
                    };
                    if (mediaStream) {
                        mediaStream.getTracks().forEach(t => t.stop());
                        mediaStream = null;
                    }
                    btnRecord.disabled = false;
                    btnStop.disabled = true;
                    panel.classList.remove('vr-recording');
                    wave.style.display = 'none';
                    btnRecord.textContent = '🎙️ 重新录音';
                    updateStatus();
                };

                mediaRecorder.start(200);
                btnRecord.disabled = true;
                btnStop.disabled = false;
                panel.classList.add('vr-recording');
                wave.style.display = 'flex';
                btnRecord.textContent = '🔴 录音中…';
                statusEl.textContent = '录音中…';
                statusEl.className = 'vr-status vr-live';
                startSpeechToText(textarea, key);
            } catch (err) {
                alert('无法访问麦克风：' + (err.message || '请检查浏览器权限设置'));
            }
        };

        btnStop.onclick = function() {
            if (recognition) { try { recognition.stop(); } catch (e) {} recognition = null; }
            if (mediaRecorder && mediaRecorder.state === 'recording') mediaRecorder.stop();
        };

        btnPlay.onclick = function() {
            const rec = store[key];
            if (!rec || !rec.blob) return;
            const audio = new Audio(URL.createObjectURL(rec.blob));
            audio.play();
        };

        btnClear.onclick = function() {
            if (confirm('确定删除本条录音吗？')) {
                delete store[key];
                btnRecord.textContent = '🎙️ 开始录音';
                updateStatus();
            }
        };

        return {
            key,
            hasRecording: () => !!(store[key] && store[key].blob),
            getRecording: () => store[key] || null,
            destroy: () => { panel.remove(); }
        };
    }

    function getByKey(key) { return store[key] || null; }
    function getAll() { return Object.entries(store).map(([k, v]) => ({ key: k, ...v })); }

    function hasContent(textarea, key) {
        const text = (textarea && textarea.value || '').trim();
        const rec = store[key];
        return text.length > 0 || !!(rec && rec.blob);
    }

    function bindSubmitValidation(formOrBtn, textarea, key, message) {
        const msg = message || '请填写文字回答，或录制语音后再提交。';
        const btn = typeof formOrBtn === 'string' ? document.getElementById(formOrBtn) : formOrBtn;
        if (!btn) return;
        btn.addEventListener('click', function(e) {
            if (!hasContent(textarea, key)) {
                e.preventDefault();
                e.stopImmediatePropagation();
                alert(msg);
                return false;
            }
        }, true);
    }

    function downloadAll(prefix) {
        const all = getAll();
        if (!all.length) { alert('没有可下载的录音文件。'); return; }
        all.forEach(rec => {
            const a = document.createElement('a');
            a.href = URL.createObjectURL(rec.blob);
            a.download = prefix + '_' + (rec.filename || rec.key + '.webm');
            a.click();
            setTimeout(() => URL.revokeObjectURL(a.href), 1000);
        });
    }

    function getManifest() {
        return getAll().map(rec => ({
            key: rec.key,
            filename: rec.filename,
            durationMs: rec.durationMs,
            mimeType: rec.mimeType,
            transcript: rec.transcript,
            meta: rec.meta
        }));
    }

    return {
        isSupported, speechSupported, attach, stopActive,
        getByKey, getAll, hasContent, bindSubmitValidation,
        downloadAll, getManifest
    };
})();
