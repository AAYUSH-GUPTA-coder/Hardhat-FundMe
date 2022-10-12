const { run } = requrie("hardhat")

async function verify(contractAddress, args) {
    console.log("Verifying contract...")
    try {
        await run("verify:verify", {
            address: contractAddress,
            constructorArguments: args,
        })
    } catch (e) {
        if (e.message.toLowerCase().includes("already verfied")) {
            console.log("Already verfied")
        } else {
            console.log(e)
        }
    }
}

module.exports = { verify }
