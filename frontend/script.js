import { ethers } from "./ethers-6.7.esm.min.js"
import { abi, contract_address } from "./constant.js"

const connectBtn = document.getElementById("connect-btn")
const startDraw = document.getElementById("draw-btn")
const entryBtn = document.getElementById("entry-btn")

connectBtn.addEventListener("click", async () => {
    if (typeof window.ethereum !== "undefined") {
        try {
            await ethereum.request({ method: "eth_requestAccounts" })
            let accounts = await ethereum.request({ method: "eth_accounts" })
            connectBtn.innerHTML = `Connected ${accounts[0].substring(0, 6)}...${accounts[0].substring(39, 42)}`

        } catch (e) {
            console.log(e)

        }
    }
    else {
        connectBtn.innerHTML = "Please install metamask"
    }
})

entryBtn.addEventListener("click", async () => {
    let ethAmount = document.getElementById("input-btn").value.trim() || "0.0001";
    if (typeof window.ethereum !== "undefined") {
        let provider = new ethers.BrowserProvider(window.ethereum)
        await provider.send('eth_requestAccounts', [])
        const signer = await provider.getSigner()
        const contract = new ethers.Contract(contract_address, abi, signer)
        try {
            let txnResponse = await contract.enter({ value: ethers.parseEther(ethAmount) })
            await txnResponse.wait(1)
        } catch (e) {
            console.log(e)
        }

    }
})

startDraw.addEventListener("click", async () => {
    if (typeof window.ethereum !== "undefined") {
        let provider = new ethers.BrowserProvider(window.ethereum)
        await provider.send('eth_requestAccounts', [])
        const signer = await provider.getSigner()
        const contract = new ethers.Contract(contract_address, abi, signer)
        try {
            let txnresponse = await contract.initiateDraw()
            await txnresponse.wait(1)
        } catch (e) {
            console.log(e.message)
        }
    }
})